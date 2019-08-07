class Store < ApplicationRecord
  # 3 days before trial end we send "trial ending" email
  DAYS_BEFORE_TRIAL_ENDS_TO_NOTIFY_USER = 3

  # we give 5 days of grace period after trial ends
  DAYS_AFTER_TRIAL_ENDS_TO_NOTIFY_USER = 5

  TRIAL_PERIOD      = (ENV['TRIAL_PERIOD'] || 30.days).freeze
  GRACE_PERIOD_DAYS = 5

  DAYS_AFTER_DEACTIVATION_TILL_MISS_YOU_EMAIL = 20
  DAYS_AFTER_DEACTIVATION_TILL_DELETED_EMAIL  = 30

  include Filterable
  include Reviewable

  include Stores::ActivatedAddons
  include Stores::Billable
  include Stores::Emails
  include Stores::WithBundle

  include Stores::Settings
  include Stores::EnabledInSettings
  include Stores::ShopifyLimit

  include Stores::Onboarding

  ## Associations
  belongs_to :user
  belongs_to :ecommerce_platform

  has_many :social_accounts,              through:   :user

  has_many :products,                     dependent: :destroy
  has_many :product_groups,               dependent: :destroy
  has_many :products_sync_batches,        dependent: :destroy

  has_many :customers,                    dependent: :destroy

  has_many :orders,                       through:   :customers
  has_many :review_requests,              through:   :customers
  has_many :customer_transaction_items,   through:   :customers,       source:    :transaction_items
  has_many :transaction_items,            as:        :reviewable,      dependent: :destroy

  has_many :review_request_emails,        through:   :review_requests, source:    :emails

  has_many :reviews,                      through:   :customers
  has_many :review_reviewables,           as:        :reviewable,         dependent: :destroy
  has_many :business_reviews,             through:   :review_reviewables, source: :review

  has_many :media,                        through:   :reviews

  has_many :imported_reviews,             through:   :customers
  has_many :imported_questions,           through:   :products

  has_many :imported_review_requests,     through:   :customers

  has_many :questions,                    through:   :products,        source:    :individual_questions

  has_many :comments,                     through:   :user

  has_many :promotions,                   dependent: :destroy
  has_many :discount_coupons,             dependent: :destroy
  has_many :coupon_codes,                 through:   :discount_coupons
  has_many :review_request_coupon_codes,  through:   :coupon_codes

  has_many :review_social_posts,          through:   :reviews,         source:    :social_posts
  has_many :question_social_posts,        through:   :questions,       source:    :social_posts

  has_many :suppressions,                 dependent: :destroy

  has_many :chargebee_customers,          dependent: :destroy

  has_many :downloads,                    dependent: :destroy

  ## Delegates
  delegate :facebook_connected?,
           :facebook_pages,
           :facebook_account,
           :koala,
           :koala_page,
           :twitter_connected?,
           :twitter_client,
           :twitter_account,
           :pinterest_connected?,
           :deleted_at,
           to: :user

  delegate :email, to: :user, prefix: true

  alias_attribute :shopify_domain, :domain
  alias_attribute :shopify_token,  :access_token

  ## Callbacks
  after_create        :assign_agent_default_name
  after_create        :complete_onboarding_embed_widgets_step, if: :ecwid?

  after_save          :trigger_review_requests, :check_uninstalled, :sync_storefront_status
  after_destroy       :intercom_destroy_sync

  ## Validations
  validates :name, :legal_name, presence: true
  validates :url, url: { schemes: %w(http https) }

  ## Enums
  enum status:            [:active, :inactive] # TODO this should not be called just status. This is not store status, it is review_requests status
  enum storefront_status: [:active, :inactive], _prefix: :storefront

  ## Scopes
  # TODO this should be just an enum - active, inactive but it's taken at the moment. >
  scope :installed,                 -> { where('access_token is not null') }
  scope :uninstalled,               -> { where('access_token is null') }
  # <

  scope :with_media_reviews,        -> { joins(reviews: :media).distinct(:store) }
  # scope :without_media_reviews,     -> { joins(questions: :social_posts).distinct(:store) } # TODO this scope needs to be done

  scope :with_product_groups,       -> { joins(:product_groups).distinct(:store) }
  scope :without_product_groups,    -> { left_outer_joins(:product_groups).where(product_groups: { store_id: nil }) }

  scope :with_socialized_reviews,   -> { joins(reviews: :social_posts).distinct(:store) }
  scope :with_socialized_questions, -> { joins(questions: :social_posts).distinct(:store) }
  scope :recently_updated,          -> { where('updated_at > ?', 12.hours.ago) }

  scope :have_sync_error, -> { where('last_sync_error_at IS NOT NULL') }

  scope :with_outdated_metafields, -> { shopify.where("(updated_at - shopify_metafields_synced_at) > INTERVAL'1 hour'")}

  ##
  mount_uploader :logo, LogoUploader

  def provider
    ecommerce_platform&.name
  end

  EcommercePlatform::SUPPORTED_PLATFORMS.each do |provider|
    scope provider, -> { where(ecommerce_platform: EcommercePlatform.send(provider)) }

    define_method("#{provider}?") { self.provider == provider.to_s }
  end

  def downloads_enabled?
    Flipper[:downloads].enabled? self
  end

  def promotions_enabled?
    Flipper[:promotions].enabled? self
  end

  def installed?
    access_token.present?
  end

  def social_connections
    [
      {
        provider: :facebook,
        connected: facebook_active?
      },
      {
        provider: :twitter,
        connected: twitter_profile_connected?
      }
    ]
  end

  def plan_price
    cache_key = [self, 'latest_plan_price', Plan.latest_timestamp]
    Rails.cache.fetch cache_key do
      previous_bundle = active_bundle || bundles.disabled.last || bundles.processing.last
      previous_bundle&.plan_price || Plan.latest_price(ecommerce_platform)&.price_in_cents || 0
    end
  end

  def abuse_reports
    AbuseReport.where('(abusable_type = ? AND abusable_id IN (?)) OR
                       (abusable_type = ? AND abusable_id IN (?)) OR
                       (abusable_type = ? AND abusable_id IN (?))',
                      'Review', review_ids,
                      'Question', question_ids,
                      'Comment', comment_ids)
  end

  def theme_css
    theme = "hc-theme__#{settings(:design).theme}"
    theme += " hc-theme__border_style-rounded" if settings(:design).rounded.to_b
    theme += " hc-theme__shadow_style-shadow" if settings(:design).shadows.to_b
    theme
  end

  def current_theme
    return settings(:design).theme
  end

  def facebook_active?
    facebook_connected? && facebook_page_connected?
  end

  def facebook_page_connected?
    settings(:social_accounts).facebook_page_id.present?
  end

  def twitter_active?
    twitter_profile_connected?
  end

  def twitter_profile_connected?
    twitter_connected? # TODO: && self.settings(:social_accounts).twitter_user_id.present?
  end

  def pinterest_profile_connected?
    false
  end

  def has_pending_imported_reviews?
    !settings(:background_workers).migrating_imported_reviews && imported_reviews.any?
  end

  def has_pending_imported_review_requests?
    !settings(:background_workers).migrating_imported_review_requests && imported_review_requests.any?
  end

  def has_pending_imported_questions?
    !settings(:background_workers).migrating_imported_questions && imported_questions.any?
  end

  def has_on_hold_review_requests?
    review_requests.on_hold.any?
  end

  def manages_products?
    provider == 'custom'
  end

  def active_products_count
    Rails.cache.fetch [self, 'active_products_count'] do
      products.active.count
    end
  end

  def accepts_repeated_reviews?
    setting_truthy? :reviews, :repeated_reviews
  end

  def show_media_gallery?
    settings(:reviews).show_media_gallery.to_b
  end

  def time_zone
    ActiveSupport::TimeZone[settings(:global).time_zone]
  end

  def locale
    settings(:global).locale ||= :en
  end

  def get_scheduled_for
    scheduled_for = DateTime.current + settings(:reviews).days_to_send_review_request.days
    notify_time   = settings(:global).notify_customers_at
    scheduled_for += 1.day if scheduled_for.hour > notify_time.hour || (scheduled_for.hour == notify_time.hour &&
                                                                                        scheduled_for.min >= notify_time.min)
    scheduled_for.beginning_of_day + notify_time.hour.hours + notify_time.min.minutes
  end

  def recent_reviews(page: 1, per_page: 10)
    reviews.with_unsuppressed_products.published.latest.paginate(page: page, per_page: per_page)
  end

  def recent_questions(page: 1, per_page: 10)
    questions.with_unsuppressed_products.published.latest.paginate(page: page, per_page: per_page)
  end

  def published_reviews_count
    Rails.cache.fetch [self, 'reviews/with-unsuppressed-products/published/count'] do
      reviews.with_unsuppressed_products.published.count
    end
  end

  def published_questions_count
    Rails.cache.fetch [self, 'questions/with-unsuppressed-products/published/count'] do
      questions.with_unsuppressed_products.published.count
    end
  end

  # TODO ~ needs testing

  def self.with_social_posts_count
    from_reviews = 'SELECT DISTINCT "store_id" FROM "stores" INNER JOIN "customers" ON
                   "customers"."store_id" = "stores"."id" INNER JOIN "reviews" ON
                   "reviews"."customer_id" = "customers"."id" INNER JOIN "social_posts" ON "social_posts"."postable_id" = "reviews"."id"
                   AND "social_posts"."postable_type" = \'Review\''
    from_questions = 'SELECT DISTINCT "store_id" FROM "stores" INNER JOIN "products" ON "products"."store_id" = "stores"."id" INNER JOIN "questions" ON
                     "questions"."product_id" = "products"."id" INNER JOIN "social_posts" ON
                     "social_posts"."postable_id" = "questions"."id" AND "social_posts"."postable_type" = \'Question\''
    from_both = "SELECT COUNT(*) FROM (#{from_reviews} UNION #{from_questions}) AS un"
    ActiveRecord::Base.connection.execute(from_both).first['count']
  end

  def self.with_social_posts
    ids = Store.with_socialized_reviews.map(&:id)
    ids += Store.with_socialized_questions.map(&:id)
    Store.where(id: ids)
  end

  def self.without_social_posts
    ids = Store.with_socialized_reviews.map(&:id)
    ids += Store.with_socialized_questions.map(&:id)
    Store.where.not(id: ids)
  end

  def social_posts
    review_social_posts + question_social_posts
  end

  def statuses
    {
      storefront: storefront_status == 'active' ? 1 : 0 ,
      backend: status == 'active' ? 1 : 0
    }
  end

  def change_template_language(lang)
    update_settings :reviews,
                  review_request_mail_subject:           I18n.t('default_templates.email.review_request_mail_subject',           locale: lang),
                  review_request_mail_body:              I18n.t('default_templates.email.review_request_mail_body',              locale: lang),
                  repeat_review_request_mail_body:       I18n.t('default_templates.email.repeat_review_request_mail_body',       locale: lang),
                  repeat_review_request_mail_subject:    I18n.t('default_templates.email.repeat_review_request_mail_subject',    locale: lang),
                  comment_mail_subject:                  I18n.t('default_templates.email.review_answer_mail_subject',            locale: lang),
                  comment_mail_body:                     I18n.t('default_templates.email.review_answer_mail_body',               locale: lang),
                  critical_review_followup_mail_subject: I18n.t('default_templates.email.critical_review_followup_mail_subject', locale: lang),
                  critical_review_followup_mail_body:    I18n.t('default_templates.email.critical_review_followup_mail_body',    locale: lang),
                  positive_review_followup_mail_subject: I18n.t('default_templates.email.positive_review_followup_mail_subject', locale: lang),
                  positive_review_followup_mail_body:    I18n.t('default_templates.email.positive_review_followup_mail_body',    locale: lang)

    update_settings :questions, comment_mail_subject:
                  I18n.t('default_templates.email.question_answer_mail_subject',          locale: lang),
                  comment_mail_body:                   I18n.t('default_templates.email.question_answer_mail_body',             locale: lang)
    update_settings :promotions, with_incentive_text:
                  I18n.t('front.with_incentive.reviews.text',                             locale: lang)
  end

  def reindex_children
    StoreReindexer.new(self).reindex_all
  end

  def install(access_token:, ecommerce_platform:)
    update_attributes access_token:       access_token,
                      ecommerce_platform: ecommerce_platform,
                      installed_at:       DateTime.current,
                      uninstalled_at:     nil
    AfterShopifyStoreInstallWorker.perform_async(id)
  end

  def reset_token
    update_attributes access_token: nil
  end

  def uninstall
    update_attributes access_token:   nil,
                      status:         'inactive',
                      installed_at:   nil,
                      uninstalled_at: DateTime.current
  end

  # Widget methods
  def product_tabs_open_forms_in_new_tab?
    setting_truthy? :widgets, :product_tabs_open_forms_in_new_tab
  end

  def product_tabs_show_reviews_header?
    setting_truthy? :widgets, :product_tabs_show_reviews_header
  end

  def product_tabs_show_questions_header?
    setting_truthy? :widgets, :product_tabs_show_questions_header
  end

  def product_tabs_hide_overviews?
    setting_truthy? :widgets, :product_tabs_hide_overviews
  end

  def product_tabs_hide_filters?
    setting_truthy? :widgets, :product_tabs_hide_filters
  end

  def review_slider_c2a_text
    use_default_text = setting_truthy?(:widgets, :review_slider_c2a_text_use_default) ||
                       settings(:widgets).review_slider_c2a_text_custom.empty?

    if use_default_text
      I18n.t('review_slider_c2a_text', scope: 'settings.default', locale: settings(:global).locale)
    else
      settings(:widgets).review_slider_c2a_text_custom
    end
  end

  def review_slider_c2a_url
    use_default_url = setting_truthy?(:widgets, :review_slider_c2a_url_use_default) ||
                      settings(:widgets).review_slider_c2a_url_custom.empty?

    if use_default_url
      Rails.application.routes.url_helpers.front_reviews_url(self, Rails.configuration.action_controller.default_url_options)
    else
      settings(:widgets).review_slider_c2a_url_custom
    end
  end

  def review_slider_open_product_in_new_tab
    setting_truthy? :widgets, :review_slider_open_product_in_new_tab
  end

  def review_journal_open_links_in_new_tab
    setting_truthy? :widgets, :review_journal_open_links_in_new_tab
  end

  def review_journal_disable_product_links
    settings(:widgets).review_journal_disable_product_links.to_b
  end

  def shopify_storefront_is_set_up?
    settings_truthy? :widgets, :product_rating_in_use,
                     :product_summary_in_use, :product_tabs_in_use, :stylesheet_in_use
  end

  def shopify_storefront_partially_set_up?
    setting_truthy?(:widgets, :product_rating_in_use) ||
    setting_truthy?(:widgets, :product_summary_in_use) ||
    setting_truthy?(:widgets, :product_tabs_in_use) ||
    setting_truthy?(:widgets, :stylesheet_in_use)
  end

  def shopify_storefront_removed?
    settings_falsy? :widgets, :product_rating_in_use,
                    :product_summary_in_use, :product_tabs_in_use, :stylesheet_in_use
  end

  def update_settings(top_level, args = {})
    settings(top_level)&.update(args)
  end

  def items_per_page
    settings(:design).items_per_page
  end

  def hide_card_actions?
    setting_truthy? :design, :hide_card_actions
  end

  def accepts_storefront_reviews?(guest_customer_present = true)
     easy_reviews? || (authenticated_reviews? && guest_customer_present)
  end

  def shopify_sync_allowed?
    syncing_real_store_in_dev = !Rails.env.production? && Rails.configuration.dev_stores.none? { |d| name.include?(d) }
    installed? && shopify? && !syncing_real_store_in_dev
  end

  def auto_inject_try_performed?
    setting_truthy? :shopify, :auto_inject_try_performed
  end

  def show_shopify_installation_processing?
    shopify? &&
    !auto_inject_try_performed?
  end

  def show_shopify_check_installation?
    shopify? &&
    auto_inject_try_performed? &&
    Time.now.utc - settings(:shopify).installation_last_checked > 1.minute
  end

  def show_shopify_installation_successful?
    shopify? && shopify_storefront_is_set_up? && auto_inject_try_performed? && !show_shopify_check_installation?
  end

  def show_shopify_installation_failed?
    shopify? && !shopify_storefront_is_set_up? && auto_inject_try_performed? && !show_shopify_check_installation?
  end

  def custom_stylesheet_active
    store.settings(:design).custom_stylesheet_active.to_b
  end

  def custom_stylesheet_code
    store.settings(:design).custom_stylesheet_code.to_s.gsub(/\s+/," ")
  end

  def avatar_visible?
    store.settings(:design).show_user_avatar.to_b
  end

  def logo_visible?
    store.settings(:design).show_store_logo_on_comment.to_b
  end

  def display_logo
    store.logo&.url
  end

  protected

  def assign_agent_default_name
    update_settings(:agents, default_name: user.display_name) if settings(:agents).default_name.blank?
  end

  def complete_onboarding_embed_widgets_step
    update_settings :onboarding, widgets_embedded: true
  end

  def trigger_review_requests
    HoldReviewRequestsWorker.perform_async(id) if saved_change_to_status? && inactive?
  end

  def check_uninstalled
    return if !saved_change_to_access_token? || user.blank?

    if installed?
      user.reactivate
    else
      user.deactivate
    end
  end

  def sync_storefront_status
    SyncGlobalMetafieldsWorker.perform_async(id) if shopify? && saved_change_to_storefront_status? && installed?
  end

  def intercom_destroy_sync
    DestroyIntercomCompanyWorker.perform_async(id)
  end

  alias_attribute :flipper_id, :id_from_provider
end

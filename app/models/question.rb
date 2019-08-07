class Question < ApplicationRecord

  include Filterable
  include ReadMore
  include Abusable

  before_create :set_submitted_at, :mask_email_in_body, :reindex_children
  after_create  :verify
  after_commit  :shopify_sync
  after_commit  :reindex_children

  ## Associations
  belongs_to :product, touch: true
  belongs_to :customer, touch: true

  has_one    :comment,       as: :commentable, dependent: :destroy

  has_many   :social_posts,  as: :postable,    dependent: :destroy
  has_many   :emails,        as: :emailable,   dependent: :destroy

  has_many   :votes,         as: :votable,     dependent: :destroy
  has_many   :flags,         as: :flaggable,   dependent: :destroy
  has_many   :abuse_reports, as: :abusable,    dependent: :destroy


  ## Enums
  enum status:       [ :pending,    :published,            :archived,             :suppressed ]
  enum verification: [ :unverified, :verified_by_merchant, :verified_by_provider              ]

  delegate :display_name, :display_first_name, :display_initials, to: :customer
  delegate :store,        to: :product
  delegate :user,         to: :store

  accepts_nested_attributes_for :customer

  ## Validations
  validates_presence_of :product, :customer, :body
  validates_length_of   :body, minimum: 1, maximum: 6000
  validates             :submitted_at, not_in_future: true

  ## Scopes
  scope :latest,                     -> { order(submitted_at: :desc) }
  scope :by_created_at,              -> { order(created_at: :desc) }
  scope :status,                     -> (status) { where(status: status) }
  scope :product_id,                 -> (product_id) { where(product_id: product_id) }
  scope :answered,                   -> { joins(:comment).distinct }
  scope :unanswered,                 -> { left_outer_joins(:comment).where(comments: { commentable_id: nil }) }

  scope :with_social_posts,          -> { joins(:social_posts).distinct(:question) }
  scope :without_social_posts,       -> { left_outer_joins(:social_posts).where(social_posts: { postable_id: nil }).distinct(:question) }

  scope :with_unsuppressed_products, -> { joins(:product).where(products: { suppressed: false }) }

  searchkick word_start:  [ :body, :comment, :customer_email, :display_name, :product_name ],
             highlight:   [ :body, :comment, :customer_email, :display_name, :product_name ],
             callbacks:   false

  scope :search_import, -> {
    includes(:comment)
      .includes(customer: { store: :setting_objects})
      .includes(product: [{ store: :setting_objects},
                          :groups, :grouped_products])
  }

  def search_data
    {
      body:              body,
      comment:           comment&.body,
      customer_email:    customer.email,
      display_name:      display_name,
      product_id:        product_id,
      product_group_ids: product.groups.any? ? product.grouped_products.pluck(:id) : [product_id],
      product_name:      product.name,
      store_id:          store.id,
      status:            status,
      updated_at:        updated_at,
      created_at:        created_at
    }
  end

  def self.search_fields
    [:body, :comment, :customer_email, :display_name, :product_name, { status: :exact }]
  end

  def self.sort_mapper
    {
      latest:        { updated_at: { order: :desc, unmapped_type: :long } },
      by_created_at: { created_at: { order: :desc, unmapped_type: :long } }
    }
  end

  def self.to_csv(timezone = Time.zone)
    Export::QuestionsCsvExport.new(questions: all, timezone: timezone).generate
  end

  def verified?
    verified_by_merchant? || verified_by_provider?
  end

  def posted_on?(provider)
    social_posts.where(provider: SocialPost.providers[provider]).any?
  end

  def facebook_post_body
    store.settings(:questions).facebook_post_template.parse_placeholders(Placeholders::QUESTION_FACEBOOK_POST, self, true)
  end

  def tweet_body
    store.settings(:questions).tweet_template.parse_placeholders(Placeholders::QUESTION_TWEET, self, true).strip
  end

  def verify
    if self.customer.transaction_items.with_orders.where(reviewable: self.product).any?
      self.verified_by_provider!
    elsif self.customer.transaction_items.with_review_requests.where(reviewable: self.product).any?
      self.verified_by_merchant!
    elsif self.customer.reviews.joins(:review_reviewables).where('review_reviewables.reviewable_id = ? AND review_reviewables.reviewable_type = ?', self.product.id, Product.name).verified_by_merchant.any?
      self.verified_by_merchant!
    else
      self.unverified!
    end
  end

  def self.abusable_fields
    ['body']
  end

  def self.statuses_updatable_to
    %w[published archived]
  end

  def suppress
    suppressed!
  end

  private

  def mask_email_in_body
    self.body = self.body.mask_email
  end

  def set_submitted_at
    self.submitted_at = created_at if submitted_at.blank?
  end

  def shopify_sync
    product.sync_shopify_metafields
  end

  def reindex_children
    return unless saved_changes.keys.length > 1 # when callback is caused by touch (only updated_at is changed) and there's nothing to reindex
    ReindexChildWorker.perform_async('Question', id)
  end

end

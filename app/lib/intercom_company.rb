class IntercomCompany
  attr_reader :company

  def initialize(company)
    @company = company
  end

  def self.build_params(store)
    {
      company_id:        store.id,
      name:              store.name,
      custom_attributes: {
        installed_at:               store.created_at,
        hc_id:                      store.hashid,
        web_address:                store.url,
        provider:                   store.provider,
        id_from_provider:           store.id_from_provider,
        review_request_status:      store.status,
        storefront_status:          store.storefront_status,
        time_zone:                  store.settings(:global).time_zone,
        storefront_language:        'English',
        easy_reviews:               store.easy_reviews?,
        auto_publish:               store.settings(:reviews).auto_publish.to_b,
        minimum_ratings_to_publish: store.settings(:reviews).minimum_ratings_to_publish.to_i,
        sidebar_autoembed:          store.settings(:widgets).sidebar.to_b,
        product_groups:             0,
        products:                   0,
        review_requests:            0,
        reviews:                    0,
        questions:                  0,
        social_posts:               0,
        trial_started_at:           store.trial_started_at,
        trial_ends_at:              store.trial_ends_at,
        billing_status:             store.billing_status
      }
    }
  end

  def update(store)
    company.name = store.name

    add_custom_attribute 'installed_at',          store.installed_at
    add_custom_attribute 'uninstalled_at',        store.uninstalled_at
    add_custom_attribute 'hc_id',                 store.hashid
    add_custom_attribute 'web_address',           store.url
    add_custom_attribute 'provider',              store.provider
    add_custom_attribute 'id_from_provider',      store.id_from_provider
    add_custom_attribute 'review_request_status', store.status
    add_custom_attribute 'storefront_status',     store.storefront_status

    add_store_settings_info store
    add_store_stats store
    add_billing_info store

    add_custom_attribute('first_review_received_at', store.reviews.organic.by_created_at.last.created_at) if has_organic_reviews?(store)

    company
  end

  private

  def has_organic_reviews?(store)
    store.reviews.organic.any?
  end

  def add_store_settings_info(store)
    add_custom_attribute 'time_zone',           store.settings(:global).time_zone
    add_custom_attribute 'storefront_language', FrontLanguage::HASH[store.settings(:global).locale.to_sym]
    add_custom_attribute 'easy_reviews',        store.easy_reviews?
    add_custom_attribute 'auto_publish',        store.settings(:reviews).auto_publish.to_b
    add_custom_attribute 'minimum_ratings_to_publish',        store.settings(:reviews).minimum_ratings_to_publish.to_i
    add_custom_attribute 'sidebar_autoembed',   store.settings(:widgets).sidebar.to_b
  end

  def add_store_stats(store)
    add_custom_attribute 'product_groups',  store.product_groups.count
    add_custom_attribute 'products',        store.products.count
    add_custom_attribute 'review_requests', store.review_requests.count
    add_custom_attribute 'reviews',         store.reviews.count
    add_custom_attribute 'questions',       store.questions.count
    add_custom_attribute 'social_posts',    store.social_posts.count
  end

  def add_billing_info(store)
    add_custom_attribute 'plan_name',         store.subscription? ? store.active_subscription.plan_name : store.billing_status
    add_custom_attribute 'current_add_ons',   store.active_addons.join(', ')
    add_custom_attribute 'trial_started_at',  store.trial_started_at
    add_custom_attribute 'trial_ends_at',     store.trial_ends_at
    add_custom_attribute 'billing_status',    store.billing_status
  end


  def add_custom_attribute(key, value)
    company.custom_attributes[key] = value
  end
end

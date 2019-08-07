Sidekiq.default_worker_options = { backtrace: true, retry: 0 }
require "sidekiq/throttled"
Sidekiq::Throttled.setup!

Rails.configuration.sidekiq_limits = ActiveSupport::OrderedOptions.new
limits = Rails.configuration.sidekiq_limits
limits.concurrency_min = 1
limits.concurrency_shopify_max = 5
limits.concurrency_max = 10
limits.threshold_shopify_max = 120 # jobs per minute
limits.threshold_shopify_min = 60 # jobs per minute
limits.threshold_max = 300 # jobs_per_minute

sidekiq_redis_url = Rails.env.production? ? ENV['REDISCLOUD_URL'] : "redis://localhost:6379"

Sidekiq.configure_server do |config|
  config.redis = { url: sidekiq_redis_url }
end

Sidekiq.configure_client do |config|
  config.redis = { url: sidekiq_redis_url }
end

class ThrottlingConfig
  attr_reader :limits

  def initialize(limits)
    @limits = limits
  end

  # general throttling when store could be Shopify or Ecwid or other platform
  def ecommerce_throttle_params
    threshold_limit = -> (*args) do
      store = Store.find_by args.first
      store&.shopify? ? shopify_threshold_limit(store.id) : limits.threshold_max
    end

    concurrency_limit = -> (*args) do
      store = Store.find_by args.first
      store&.shopify ? shopify_concurrency_limit(store.id) : limits.concurrency_max
    end

    throttle_params threshold_limit, concurrency_limit
  end

  # Throttling for Shopify stores
  def shopify_throttle_params
    threshold_limit = -> (*args) { shopify_threshold_limit(args.first) }
    concurrency_limit = -> (*args) { shopify_concurrency_limit(args.first) }
    throttle_params(threshold_limit, concurrency_limit)
  end

  # Throttling for all other stores ( Ecwid, Lemonstand )
  # when we're sure that store is not Shopify
  def ecwid_throttle_params
    throttle_params limits.threshold_max, limits.concurrency_max
  end

  private

  def throttle_params(threshold_limit, concurrency_limit)
    {
      threshold: {
        limit: threshold_limit,
        period: 1.minute,
        key_suffix: -> (*args) { args.first }
      },
      concurrency: {
        limit: concurrency_limit,
        key_suffix: -> (*args) { args.first }
      }
    }
  end

  # while Shopify usage is not close to limit - 2 requests/second,
  # after - 1 request per 3 seconds
  def shopify_threshold_limit(store_id)
    ShopifyApiUsage.new(store_id).limit_exceeded? ? limits.threshold_shopify_min : limits.threshold_shopify_max
  end

  def shopify_concurrency_limit(store_id)
    ShopifyApiUsage.new(store_id).limit_exceeded? ? limits.concurrency_min : limits.concurrency_shopify_max
  end
end

config = ThrottlingConfig.new(limits)

Sidekiq::Throttled::Registry.add(:ecommerce_api, config.ecommerce_throttle_params)
Sidekiq::Throttled::Registry.add(:shopify_api, config.shopify_throttle_params)
Sidekiq::Throttled::Registry.add(:ecwid_api, config.ecwid_throttle_params)

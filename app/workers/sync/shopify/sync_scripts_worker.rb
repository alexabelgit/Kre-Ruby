class SyncScriptsWorker
  include Sidekiq::Worker

  include Sidekiq::Throttled::Worker
  sidekiq_throttle_as :shopify_api

  sidekiq_options queue: :critical, retry: Shopify::ApiWrapper::MAX_RETRIES

  def perform(store_id)
    store = Store.find_by id: store_id
    return unless store&.shopify_sync_allowed?

    Time.zone = store.time_zone
    Sync::ShopifyService.new(store: store).scripts
  end
end

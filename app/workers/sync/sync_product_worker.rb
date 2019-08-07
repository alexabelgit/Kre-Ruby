class SyncProductWorker
  include Sidekiq::Worker

  include Sidekiq::Throttled::Worker
  sidekiq_throttle_as :shopify_api

  sidekiq_options queue: :default, retry: Shopify::ApiWrapper::MAX_RETRIES

  def perform(store_id, product_id_from_provider)
    store = Store.find_by id: store_id
    return if store.blank? || !store.installed?

    Time.zone = store.time_zone
    sync_service = SyncService.new(store: store)
    Store.no_touching do
      sync_service.product(id_from_provider: product_id_from_provider)
    end
    store.touch_later
  end
end

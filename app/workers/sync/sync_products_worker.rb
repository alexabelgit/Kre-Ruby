class SyncProductsWorker
  include Sidekiq::Worker

  include Sidekiq::Throttled::Worker
  sidekiq_throttle_as :shopify_api

  sidekiq_options queue: :default

  def perform(store_id)
    store = Store.find_by id: store_id
    return if store.blank? || !store.installed?

    Time.zone = store.time_zone
    sync_service = SyncService.new(store: store)
    Store.no_touching do
      store.products.find_each do |product|
        sync_service.product(id_from_provider: product.id_from_provider)
      end
    end
   
    store.touch_later
  end
end
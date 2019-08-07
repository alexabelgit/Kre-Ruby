class ImportProductsWorker
  include Sidekiq::Worker

  include Sidekiq::Throttled::Worker
  sidekiq_throttle_as :ecommerce_api

  sidekiq_options queue: :default

  def perform(store_id)
    store = Store.find_by id: store_id
    return unless store.present?
    return unless store.installed?

    Time.zone = store.time_zone

    store.update_settings :background_workers, product_seed_running: true

    sync_service = SyncService.new(store: store)
    Searchkick.callbacks(false) do
      sync_service.products(skip_reindex_children: true)
    end
  end
end

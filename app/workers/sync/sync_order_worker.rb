class SyncOrderWorker
  include Sidekiq::Worker

  include Sidekiq::Throttled::Worker
  sidekiq_throttle_as :ecommerce_api

  sidekiq_options queue: :default, retry: Shopify::ApiWrapper::MAX_RETRIES

  def perform(store_id, order_id_from_provider, import = false)
    store = Store.find_by id: store_id
    return unless store&.installed?

    Time.zone = store.time_zone
    if store.installed?
      sync_service = SyncService.new(store: store)

      if import
        Searchkick.callbacks(false) do
          ApplicationRecord.no_touching do
            sync(sync_service, order_id_from_provider, import)
          end
        end
        store.decrement!(:number_of_orders_to_import)
        unless store.reload.number_of_orders_to_import.positive?
          store.reindex_children
          store.update_settings :background_workers,
                                order_seed_running: false,
                                orders_seeded: true
        end
      else
        sync(sync_service, order_id_from_provider, import)
      end
    end
  end

  def sync(sync_service, order_id_from_provider, import)
    service_result_order = sync_service.order(id_from_provider: order_id_from_provider, import: import)
    sync_service.review_request(order_id_from_provider: service_result_order.id_from_provider,
                                service_result_order: service_result_order) if service_result_order
  end
end

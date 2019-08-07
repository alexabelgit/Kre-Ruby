class SyncOrderJob < ApplicationJob

  ### SIDEKIQED

  queue_as :default

  def perform(store_id, order_id_from_provider)
    store = Store.find_by_id(store_id)
    return unless store.present?
    return unless store.installed?

    Time.zone = store.time_zone
    if store.installed?
      sync_service = SyncService.new(store: store)
      service_result_order = sync_service.order(id_from_provider: order_id_from_provider, import: false)
      sync_service.review_request(order_id_from_provider: service_result_order.id_from_provider,
                                  service_result_order: service_result_order) if service_result_order
    end
  end
end

class ImportOrdersJob < ApplicationJob
  queue_as :default

  ### SIDEKIQED  

  def perform(store_id, date_from, date_to)
    store = Store.find_by_id(store_id)
    return unless store.present?
    return unless store.installed?

    Time.zone = store.time_zone
    if store.installed?
      date_from = Date.parse(date_from)
      date_to = Date.parse(date_to)
      store.settings(:background_workers).update_attributes!(order_seed_running: true)
      Product.skip_callback(:commit, :after, :reindex_children)
      Searchkick.callbacks(false) do
        sync_service          = SyncService.new(store: store)
        service_result_orders = sync_service.orders(date_from: date_from, date_to: date_to, import: true)
        service_result_orders.each do |service_result_order|
          sync_service.review_request(order_id_from_provider: service_result_order.id_from_provider, service_result_order: service_result_order)
        end
      end
      Product.set_callback(:commit, :after, :reindex_children)
      store.reindex_children
      store.settings(:background_workers).update_attributes!(order_seed_running: false)
      store.settings(:background_workers).update_attributes!(orders_seeded: true)
    end
  end
end

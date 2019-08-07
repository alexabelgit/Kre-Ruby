# TODO: refactor this one
class ImportOrdersWorker
  include Sidekiq::Worker

  include Sidekiq::Throttled::Worker
  sidekiq_throttle_as :ecommerce_api

  sidekiq_options queue: :default

  def perform(store_id, date_from, date_to)
    store = Store.find_by id: store_id
    return if store.blank? || !store.installed?

    Time.zone = store.time_zone
    date_from = Date.parse(date_from)
    date_to   = Date.parse(date_to)

    store.update_settings :background_workers, order_seed_running: false

    sync_service = SyncService.new(store: store)
    order_id_from_providers = sync_service.order_id_from_providers(date_from: date_from, date_to: date_to)
    return if order_id_from_providers.count.zero?

    store.update!(number_of_orders_to_import: order_id_from_providers.count)
    order_id_from_providers.each do |order_id_from_provider|
      SyncOrderWorker.perform_uniq_in(15.seconds, store.id, order_id_from_provider, true)
    end

    store.update_settings :background_workers, orders_seeded: true
  ensure
    store&.update_settings :background_workers, order_seed_running: false
  end
end

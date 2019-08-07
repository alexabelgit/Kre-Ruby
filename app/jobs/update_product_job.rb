class UpdateProductJob < ApplicationJob
  queue_as :default

  ### SIDEKIQED

  def perform(store_id, product_id_from_provider)
    store = Store.find_by_id(store_id)
    return unless store.present?
    return unless store.installed?

    Time.zone = store.time_zone
    sync_service = SyncService.new(store: store)
    sync_service.product(id_from_provider: product_id_from_provider)
  end
end

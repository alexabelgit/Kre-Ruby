class ImportProductsJob < ApplicationJob
  queue_as :default

  ### SIDEKIQED  

  def perform(store_id)
    store = Store.find_by_id(store_id)
    return unless store.present?
    return unless store.installed?

    Time.zone = store.time_zone
    if store.installed?
      store.settings(:background_workers).update_attributes!(product_seed_running: true)
      Product.skip_callback(:commit, :after, :reindex_children)
      Searchkick.callbacks(false) do
        sync_service = SyncService.new(store: store)
        sync_service.products
      end
      Product.set_callback(:commit, :after, :reindex_children)
      store.reindex_children
      store.settings(:background_workers).update_attributes!(product_seed_running: false)
    end
  end
end

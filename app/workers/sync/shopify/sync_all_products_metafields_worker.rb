class SyncAllProductsMetafieldsWorker
  include Sidekiq::Worker

  def perform(store_id)
    store = Store.find_by id: store_id
    return unless store&.shopify_sync_allowed?

    store.products.each.with_index do |product, index|
      if index > 100
        SyncProductMetafieldsWorker.perform_in index.div(100).minutes, store.id, product.id_from_provider
      else
        SyncProductMetafieldsWorker.perform_async(store.id, product.id_from_provider)
      end
    end
  end
end
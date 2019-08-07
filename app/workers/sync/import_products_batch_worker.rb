class ImportProductsBatchWorker
  include Sidekiq::Worker

  sidekiq_options queue: :default

  def perform(batch_id)
    batch = ProductsSyncBatch.find_by id: batch_id

    return if batch.blank?

    store = batch.store

    sync_service = SyncService.new(store: batch.store)

    batch.products_info.each do |product_info|
      api_product = DataStruct.new product_info

      api_product.updated_at = api_product.updated_at&.to_datetime
      api_product.image_updated_at = api_product.image_updated_at&.to_datetime

      inputs = {
          id_from_provider: api_product.id_from_provider,
          api_product: api_product,
          skip_reindex_children: batch.skip_reindex_children?,
          skip_image_update: batch.skip_image_update?
      }
     sync_service.product inputs
    end

    batch.update processed_at: DateTime.current

    store.with_lock do
      if store.products_sync_batches.unprocessed.empty?
        store.reindex_children
        store.update_settings :background_workers, product_seed_running: false
      end
    end
  end
end

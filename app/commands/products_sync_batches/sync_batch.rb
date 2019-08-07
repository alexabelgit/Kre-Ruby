module ProductsSyncBatches
  class SyncBatch < ApplicationCommand
    object :store

    string :sync_id
    hash :arguments, default: {} do
      boolean :skip_image_update, default: false
      boolean :skip_reindex_children, default: false
    end

    array :products_info, strip: false

    def execute
      batch = ProductsSyncBatch.create given_inputs

      if batch.persisted?
        ImportProductsBatchWorker.perform_async batch.id
      end
    end
  end
end
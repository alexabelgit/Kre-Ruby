class CreateProductsSyncBatches < ActiveRecord::Migration[5.2]
  def change
    create_table :products_sync_batches do |t|
      t.references :store
      t.string :sync_id
      t.jsonb :products_info
      t.jsonb :arguments
      t.datetime :processed_at

      t.timestamps
    end
    add_index :products_sync_batches, :sync_id
    add_index :products_sync_batches, :processed_at
  end
end

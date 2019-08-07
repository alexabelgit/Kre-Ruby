class AddShopifyMetafieldsSyncedAtToProductAndStore < ActiveRecord::Migration[5.2]
  def change
    add_column :products, :shopify_metafields_synced_at, :datetime, index: true
    add_column :stores, :shopify_metafields_synced_at, :datetime, index: true
  end
end

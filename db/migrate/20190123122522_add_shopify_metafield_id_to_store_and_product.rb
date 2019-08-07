class AddShopifyMetafieldIdToStoreAndProduct < ActiveRecord::Migration[5.2]
  def change
    add_column :stores, :shopify_metafield_id, :text
    add_column :products, :shopify_metafield_id, :text
  end
end

class CreateStoreProductsUsages < ActiveRecord::Migration[5.2]
  def change
    create_view :store_products_usages, materialized: true
    add_index :store_products_usages, :store_id, unique: true
  end
end

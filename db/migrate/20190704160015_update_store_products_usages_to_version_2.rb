class UpdateStoreProductsUsagesToVersion2 < ActiveRecord::Migration[5.2]
  def change
    update_view :store_products_usages, version: 2, revert_to_version: 1, materialized: true
  end
end

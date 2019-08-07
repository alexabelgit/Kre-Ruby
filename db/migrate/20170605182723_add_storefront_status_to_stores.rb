class AddStorefrontStatusToStores < ActiveRecord::Migration[5.0]
  def change
    add_column :stores, :storefront_status, :integer, null: false, default: 0
  end
end

class AddMigratedToProductsAt < ActiveRecord::Migration[5.2]
  def change
    add_column :subscriptions, :migrated_to_products_billing_at, :datetime
  end
end

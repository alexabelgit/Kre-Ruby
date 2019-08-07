class AddGiftedProductsToSubscription < ActiveRecord::Migration[5.2]
  def change
    add_column :subscriptions, :gifted_products_amount, :integer
    add_column :subscriptions, :gifted_products_valid_till, :datetime
  end
end

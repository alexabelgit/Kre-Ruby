class AddCustomerIdToSubscription < ActiveRecord::Migration[5.1]
  def change
    add_column :subscriptions, :customer_id, :string, index: true
  end
end

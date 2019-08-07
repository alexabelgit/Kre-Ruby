class AddChargebeeCustomerToSubscriptionAndPaymentMethod < ActiveRecord::Migration[5.1]
  def change
    remove_column :payment_methods, :user_id, :integer
    remove_column :payment_methods, :customer_id, :string
    add_column :payment_methods, :chargebee_customer_id, :integer, index: true

    remove_column :subscriptions, :customer_id, :string
    add_column :subscriptions, :chargebee_customer_id, :integer, index: true
    remove_column :subscriptions, :payment_method_id
  end
end

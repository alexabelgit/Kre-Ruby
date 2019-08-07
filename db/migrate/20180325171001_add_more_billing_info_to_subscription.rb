class AddMoreBillingInfoToSubscription < ActiveRecord::Migration[5.1]
  def change
    add_column :subscriptions, :next_billing_at, :datetime
    add_column :subscriptions, :billing_interval, :string, default: 'month'
  end
end

class AddDisabledToBillingSubscription < ActiveRecord::Migration[5.0]
  def change
    add_column :billing_subscriptions, :disabled, :boolean, default: false
  end
end

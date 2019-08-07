class AddPaimentProfileIdToBillingSubscriptions < ActiveRecord::Migration[5.0]
  def change
    add_column :billing_subscriptions, :payment_profile_id, :integer
  end
end

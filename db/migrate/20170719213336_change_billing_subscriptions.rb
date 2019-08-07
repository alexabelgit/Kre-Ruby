class ChangeBillingSubscriptions < ActiveRecord::Migration[5.0]
  def up
    drop_table :add_ons

    rename_column :billing_subscriptions, :plan, :kind
  end
end

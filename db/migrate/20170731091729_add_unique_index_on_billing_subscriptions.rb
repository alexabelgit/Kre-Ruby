class AddUniqueIndexOnBillingSubscriptions < ActiveRecord::Migration[5.0]
  def change
    add_index :billing_subscriptions, [:store_id, :kind], unique: true
  end
end

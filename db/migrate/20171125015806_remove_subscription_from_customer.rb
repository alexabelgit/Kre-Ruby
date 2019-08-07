class RemoveSubscriptionFromCustomer < ActiveRecord::Migration[5.0]
  def change
    remove_column :customers, :subscription
  end
end

class AddSubscriptionToCustomers < ActiveRecord::Migration[5.0]
  def change
    add_column :customers, :subscription, :boolean, null: false, default: true
  end
end

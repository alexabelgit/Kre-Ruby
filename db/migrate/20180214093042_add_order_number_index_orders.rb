class AddOrderNumberIndexOrders < ActiveRecord::Migration[5.0]
  def change
    add_index :orders, [:customer_id, :order_number], unique: true
  end
end

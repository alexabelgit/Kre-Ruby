class AddOrderTotalToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :currency, :string, default: 'USD'
    add_column :orders, :item_total, :decimal, precision: 8, scale: 2, default: 0.0, null: false
    add_column :orders, :total, :decimal, precision: 8, scale: 2, default: 0.0, null: false
  end
end

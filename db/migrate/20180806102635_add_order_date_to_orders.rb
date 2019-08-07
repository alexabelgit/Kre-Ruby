class AddOrderDateToOrders < ActiveRecord::Migration[5.1]
  def change
    add_column :orders, :order_date, :datetime, null: true
  end
end

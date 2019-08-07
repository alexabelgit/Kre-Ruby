class AddOrderNumberToOrders < ActiveRecord::Migration[5.0]
  def change
    add_column :orders, :order_number, :string

    Order.reset_column_information
    Store.ecwid.each do |store|
      store.orders.where.not(id_from_provider: nil).each do |order|
        order.update_attributes(order_number: order.id_from_provider)
      end
    end
  end
end

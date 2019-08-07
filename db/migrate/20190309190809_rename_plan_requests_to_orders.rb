class RenamePlanRequestsToOrders < ActiveRecord::Migration[5.2]
  def change
    rename_column :plans, :requests_limit, :orders_limit
    rename_column :plans, :extended_requests_limit, :extended_orders_limit
  end
end

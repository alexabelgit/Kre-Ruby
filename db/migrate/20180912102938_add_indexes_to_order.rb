class AddIndexesToOrder < ActiveRecord::Migration[5.2]
  def change
    add_index :orders, :created_at
    add_index :orders, :order_date
  end
end

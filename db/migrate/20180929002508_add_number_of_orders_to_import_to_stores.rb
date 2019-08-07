class AddNumberOfOrdersToImportToStores < ActiveRecord::Migration[5.2]
  def change
    add_column :stores, :number_of_orders_to_import, :integer, null: false, default: 0
  end
end

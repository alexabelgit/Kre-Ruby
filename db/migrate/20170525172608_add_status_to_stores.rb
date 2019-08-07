class AddStatusToStores < ActiveRecord::Migration[5.0]
  def change
    add_column :stores, :status, :integer, null: false, default: 0
  end
end

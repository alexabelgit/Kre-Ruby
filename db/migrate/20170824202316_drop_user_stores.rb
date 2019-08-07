class DropUserStores < ActiveRecord::Migration[5.0]
  def change
    drop_table :user_stores
  end
end

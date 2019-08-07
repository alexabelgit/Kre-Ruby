class CreateUserStores < ActiveRecord::Migration[5.0]
  def change
    create_table :user_stores do |t|
      t.references :user, null: false
      t.references :store, null: false
      t.timestamps
    end
    add_index :user_stores, [:user_id, :store_id], unique: true
  end
end
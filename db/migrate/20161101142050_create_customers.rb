class CreateCustomers < ActiveRecord::Migration[5.0]
  def change
    create_table :customers do |t|
      t.references :store, null: false
      t.string :email, null: false
      t.string :name
      t.string :id_from_provider, null: false
      t.timestamps
    end
    add_index :customers, [:store_id, :id_from_provider], unique: true
  end
end
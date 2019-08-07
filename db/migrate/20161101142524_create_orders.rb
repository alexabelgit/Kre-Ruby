class CreateOrders < ActiveRecord::Migration[5.0]
  def change
    create_table :orders do |t|
      t.references :customer, null: false
      t.string :id_from_provider, null: false
      t.timestamps
    end
    add_index :orders, [:customer_id, :id_from_provider], unique: true
  end
end
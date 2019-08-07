class CreateOrderProducts < ActiveRecord::Migration[5.0]
  def change
    create_table :order_products do |t|
      t.references :order, null: false
      t.references :product, null: false
      t.timestamps
    end
    add_index :order_products, [:order_id, :product_id], unique: true
  end
end
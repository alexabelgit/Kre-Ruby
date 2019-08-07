class CreateProductGroupProducts < ActiveRecord::Migration[5.0]
  def change
    create_table :product_group_products do |t|
      t.references :product_group, null: false
      t.references :product, null: false

      t.timestamps
    end
    add_index :product_group_products, [:product_group_id, :product_id], unique: true
  end
end

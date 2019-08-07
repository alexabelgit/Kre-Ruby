class CreateProductLimitsModifiers < ActiveRecord::Migration[5.2]
  def change
    create_table :product_limits_modifiers do |t|
      t.references :store
      t.integer :additional_products
      t.datetime :starts_at, index: true
      t.datetime :ends_at, index: true
      t.text :comment

      t.timestamps
    end
  end
end

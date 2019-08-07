class CreateProductGroups < ActiveRecord::Migration[5.0]
  def change
    create_table :product_groups do |t|
      t.string :name
      t.references :store, null: false

      t.timestamps
    end
  end
end

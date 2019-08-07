class CreateProducts < ActiveRecord::Migration[5.0]
  def change
    create_table :products do |t|
      t.references :store, null: false
      t.string :name, null: false
      t.string :id_from_provider, null: false
      t.string :category
      t.string :image_url
      t.timestamps
    end
    add_index :products, [:store_id, :id_from_provider], unique: true
  end
end
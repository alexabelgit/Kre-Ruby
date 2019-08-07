class CreateStores < ActiveRecord::Migration[5.0]
  def change
    create_table :stores do |t|
      t.string :url, null: false
      t.string :name, null: false
      t.string :access_token, null: false
      t.integer :provider, null: false
      t.string :id_from_provider, null: false
      t.string :logo_url
      t.timestamps
    end
    add_index :stores, [:provider, :id_from_provider], unique: true
  end
end

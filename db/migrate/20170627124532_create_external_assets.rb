class CreateExternalAssets < ActiveRecord::Migration[5.0]
  def change
    create_table :external_assets do |t|
      t.string :name, null: false
      t.string :extension, null: false
      t.string :digest, null: false
      t.string :key, null: false
      t.string :url, null: false
      t.timestamps
    end
  end
end

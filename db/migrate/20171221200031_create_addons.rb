class CreateAddons < ActiveRecord::Migration[5.0]
  def change
    create_table :addons do |t|
      t.string :name, null: false
      t.string :description
      t.integer :state, null: false

      t.timestamps
    end
  end
end

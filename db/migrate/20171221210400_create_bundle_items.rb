class CreateBundleItems < ActiveRecord::Migration[5.0]
  def change
    create_table :bundle_items do |t|
      t.references :addon_price, null: false, index: true
      t.references :bundle, null: false, index: true

      t.integer :price_in_cents, null: false

      t.timestamps
    end
  end
end

class CreateAddonPrices < ActiveRecord::Migration[5.0]
  def change
    create_table :addon_prices do |t|
      t.references :addon, index: true, null: false
      t.references :ecommerce_platform, index: true, null: false

      t.integer :price_in_cents, null: false, default: 0
      t.datetime :deprecated_at

      t.timestamps
    end
  end
end

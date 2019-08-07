class CreatePackageDiscounts < ActiveRecord::Migration[5.0]
  def change
    create_table :package_discounts do |t|
      t.integer :addons_count

      t.integer :discount_percents
      t.integer :fixed_price_in_cents

      t.integer :round_type

      t.references :commerce_platform, null: false, index: true

      t.timestamps
    end
  end
end

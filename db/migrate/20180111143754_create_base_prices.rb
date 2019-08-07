class CreateBasePrices < ActiveRecord::Migration[5.0]
  def change
    create_table :base_prices do |t|
      t.references :ecommerce_platform, index: true
      t.string :plan_name

      t.integer :price_in_cents
      t.datetime :deprecated_at

      t.timestamps
    end
  end
end

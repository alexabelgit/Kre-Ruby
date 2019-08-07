class CreateOrdersGifts < ActiveRecord::Migration[5.2]
  def change
    create_table :orders_gifts do |t|
      t.references :bundle
      t.integer :amount
      t.datetime :applied_at, index: true

      t.timestamps
    end
  end
end

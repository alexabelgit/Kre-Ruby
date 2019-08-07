class CreateCoupons < ActiveRecord::Migration[5.0]
  def change
    create_table :coupons do |t|
      t.string :name, null: false, index: true
      t.string :description
      t.string :code, null: false, index: true
      t.integer :discount_type
      t.float :discount_value
      t.integer :state, null: false, index: true
      t.datetime :expired_at, index: true
      t.integer :available_usages

      t.references :commerce_platform, index: true, null: false

      t.timestamps
    end
  end
end

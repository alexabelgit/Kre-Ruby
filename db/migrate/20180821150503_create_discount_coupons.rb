class CreateDiscountCoupons < ActiveRecord::Migration[5.1]
  def change
    create_table :discount_coupons do |t|
      t.string     :code
      t.string     :id_from_provider
      t.datetime   :valid_from
      t.datetime   :valid_until
      t.integer    :usage_type,       default: 0, null: false
      t.references :promotion

      t.timestamps
    end
  end
end

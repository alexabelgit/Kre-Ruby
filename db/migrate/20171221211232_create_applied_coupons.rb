class CreateAppliedCoupons < ActiveRecord::Migration[5.0]
  def change
    create_table :applied_coupons do |t|
      t.references :coupon, null: false, index: true
      t.references :bundle, null: false, index: true

      t.timestamps
    end
  end
end

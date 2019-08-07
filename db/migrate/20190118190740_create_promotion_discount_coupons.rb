class CreatePromotionDiscountCoupons < ActiveRecord::Migration[5.2]
  def change
    create_table :promotion_discount_coupons do |t|
      t.references :promotion
      t.references :discount_coupon

      t.timestamps
    end
  end
end

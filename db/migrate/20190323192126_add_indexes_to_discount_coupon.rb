class AddIndexesToDiscountCoupon < ActiveRecord::Migration[5.2]
  def change
    add_index :discount_coupons, :created_at
    add_index :discount_coupons, :valid_from
    add_index :discount_coupons, :valid_until
    add_index :discount_coupons, :issue_count
    add_index :discount_coupons, :limit
  end
end

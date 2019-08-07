class AddStatusToDiscountCoupons < ActiveRecord::Migration[5.2]
  def change
    add_column :discount_coupons, :status, :integer, default: 0
  end
end

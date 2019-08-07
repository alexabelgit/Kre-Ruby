class AddDiscountSequenceToDiscountCoupons < ActiveRecord::Migration[5.2]
  def change
    add_column :discount_coupons, :discount_sequence, :integer, default: 0
  end
end

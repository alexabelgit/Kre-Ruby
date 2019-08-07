class AddCurrentToCouponCodes < ActiveRecord::Migration[5.2]
  def change
    add_column :coupon_codes, :current, :boolean, null: false, default: false
  end
end

class AddCouponCodeToStores < ActiveRecord::Migration[5.0]
  def change
    add_column :stores, :coupon_code, :string
  end
end

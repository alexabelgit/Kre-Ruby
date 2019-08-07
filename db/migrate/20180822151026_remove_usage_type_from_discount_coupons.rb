class RemoveUsageTypeFromDiscountCoupons < ActiveRecord::Migration[5.1]
  def change
    remove_column :discount_coupons, :usage_type, :integer
  end
end

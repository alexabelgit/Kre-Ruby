class RenameCommercePlatformToEcommercePlatformInCoupons < ActiveRecord::Migration[5.0]
  def change
    rename_column :coupons, :commerce_platform_id, :ecommerce_platform_id
  end
end

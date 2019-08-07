class RenameCommercePlatformToEcommercePlatformInPackageDiscounts < ActiveRecord::Migration[5.0]
  def change
    rename_column :package_discounts, :commerce_platform_id, :ecommerce_platform_id
  end
end

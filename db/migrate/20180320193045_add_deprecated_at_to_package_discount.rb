class AddDeprecatedAtToPackageDiscount < ActiveRecord::Migration[5.1]
  def change
    add_column :package_discounts, :deprecated_at, :datetime, index: true
  end
end

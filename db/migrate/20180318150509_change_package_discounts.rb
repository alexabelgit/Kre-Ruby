class ChangePackageDiscounts < ActiveRecord::Migration[5.1]
  def change
    remove_column :package_discounts, :fixed_price_in_cents, :integer
    remove_column :package_discounts, :round_type, :integer
    add_column :package_discounts, :chargebee_id, :string

    add_index :package_discounts, [:addons_count, :ecommerce_platform_id], name: 'index_package_discounts_addons_per_platform'
  end
end

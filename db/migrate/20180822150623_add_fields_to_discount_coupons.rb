class AddFieldsToDiscountCoupons < ActiveRecord::Migration[5.1]
  def change
    add_column :discount_coupons, :usage_count,              :integer, default: 0, null: false
    add_column :discount_coupons, :total_usage_limit,        :integer
    add_column :discount_coupons, :per_customer_usage_limit, :integer
    add_column :discount_coupons, :discount_amount,          :integer
    add_column :discount_coupons, :discount_type,            :string
  end
end

class AddMoreFieldsToDiscountCoupons < ActiveRecord::Migration[5.2]
  def change
    rename_column :discount_coupons, :total_usage_limit,        :limit
    rename_column :discount_coupons, :usage_count,              :issue_count

    add_column    :discount_coupons, :name,                     :string
    add_column    :discount_coupons, :code_type,                :integer,     null: false
    add_column    :discount_coupons, :send_per,                 :integer,     null: false
    add_reference :discount_coupons, :store

    remove_column :discount_coupons, :code,                     :string
    remove_column :discount_coupons, :per_customer_usage_limit, :integer
    remove_column :discount_coupons, :promotion_id,             :bigint
  end
end

class ChangeProductLimitsColumn < ActiveRecord::Migration[5.2]
  def change
    remove_column :plans, :product_limits
    add_column :plans, :min_products_limit, :integer, index: true, default: 0
    add_column :plans, :max_products_limit, :integer, default: nil, index: true
  end
end

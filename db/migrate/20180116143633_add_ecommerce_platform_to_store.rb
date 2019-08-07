class AddEcommercePlatformToStore < ActiveRecord::Migration[5.0]
  def change
    add_column :stores, :ecommerce_platform_id, :integer, index: true
    change_column_null :stores, :provider, true # allow provider to be nil since we're using ecommerce_platform instead
  end
end

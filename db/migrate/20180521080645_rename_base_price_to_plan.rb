class RenameBasePriceToPlan < ActiveRecord::Migration[5.1]
  def change
    remove_index :base_prices, :ecommerce_platform_id
    rename_table :base_prices, :plans
    add_index :plans, :ecommerce_platform_id
  end
end

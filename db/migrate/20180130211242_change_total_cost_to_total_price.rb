class ChangeTotalCostToTotalPrice < ActiveRecord::Migration[5.0]
  def change
    rename_column :bundles, :total_cost, :total_price
  end
end

class RemoveTotalPriceFromBundle < ActiveRecord::Migration[5.0]
  def change
    remove_column :bundles, :total_price, :integer
  end
end

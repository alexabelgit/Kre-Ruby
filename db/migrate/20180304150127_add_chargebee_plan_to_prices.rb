class AddChargebeePlanToPrices < ActiveRecord::Migration[5.1]
  def change
    add_column :base_prices, :chargebee_id, :string
    add_column :addon_prices, :chargebee_id, :string
  end
end

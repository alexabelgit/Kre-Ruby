class AddSlugToAddonsAndBasePrices < ActiveRecord::Migration[5.1]
  def change
    add_column :addons, :slug, :string, index: true
    add_column :base_prices, :slug, :string, index: true
  end
end

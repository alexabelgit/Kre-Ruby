class AddProductsCountToStore < ActiveRecord::Migration[5.2]
  def change
    add_column :stores, :products_count, :integer, default: 0
  end
end

class AddSkuToProduct < ActiveRecord::Migration[5.2]
  def change
    add_column :products, :skus, :string, array: true, default: [], index: true
  end
end

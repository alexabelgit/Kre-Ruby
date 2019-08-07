class AddIdFromProviderToPromotions < ActiveRecord::Migration[5.1]
  def change
    add_column :promotions, :id_from_provider, :string
  end
end

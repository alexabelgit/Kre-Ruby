class AddIncentiveToPromotions < ActiveRecord::Migration[5.2]
  def change
    add_column :promotions, :incentive, :boolean, default: false
  end
end

class AddUsageCountToPromotions < ActiveRecord::Migration[5.1]
  def change
    add_column :promotions, :usage_count, :integer, default: 0, null: false
  end
end

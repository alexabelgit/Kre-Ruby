class AddIndexesToPromotions < ActiveRecord::Migration[5.2]
  def change
    add_index :promotions, :created_at
    add_index :promotions, :starts_at
    add_index :promotions, :ends_at
  end
end

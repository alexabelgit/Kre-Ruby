class ChangeOrderProductInReviews < ActiveRecord::Migration[5.2]
  def change
    change_column :reviews, :order_product_id, :integer, null: true
  end
end

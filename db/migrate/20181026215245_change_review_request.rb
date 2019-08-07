class ChangeReviewRequest < ActiveRecord::Migration[5.2]
  def change
    change_column :review_requests, :order_id,    :integer, null: true
    add_column    :review_requests, :customer_id, :integer
  end
end

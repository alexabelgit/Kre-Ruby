class AddUniqueIndexesToReviewsAndReviewRequestReferences < ActiveRecord::Migration[5.0]
  def change
    add_index :review_requests, :order_id, unique: true, name: 'index_unique_review_requests_on_order_id'
  end
end
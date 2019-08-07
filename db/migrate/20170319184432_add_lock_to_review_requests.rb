class AddLockToReviewRequests < ActiveRecord::Migration[5.0]
  def change
    add_column :review_requests, :locked, :boolean, null: false, default: false
  end
end

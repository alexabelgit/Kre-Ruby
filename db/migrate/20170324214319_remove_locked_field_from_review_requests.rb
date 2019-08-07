class RemoveLockedFieldFromReviewRequests < ActiveRecord::Migration[5.0]
  def change
    remove_column :review_requests, :locked
  end
end

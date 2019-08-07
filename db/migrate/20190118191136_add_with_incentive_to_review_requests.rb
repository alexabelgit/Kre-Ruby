class AddWithIncentiveToReviewRequests < ActiveRecord::Migration[5.2]
  def change
    add_column :review_requests, :with_incentive, :boolean, default: false
  end
end

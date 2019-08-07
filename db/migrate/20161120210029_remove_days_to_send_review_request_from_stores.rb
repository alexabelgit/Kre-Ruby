class RemoveDaysToSendReviewRequestFromStores < ActiveRecord::Migration[5.0]
  def change
    remove_column :stores, :days_to_send_review_request
  end
end
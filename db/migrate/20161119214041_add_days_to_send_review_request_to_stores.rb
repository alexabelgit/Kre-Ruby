class AddDaysToSendReviewRequestToStores < ActiveRecord::Migration[5.0]
  def change
    add_column :stores, :days_to_send_review_request, :integer, null: false, default: 0
  end
end
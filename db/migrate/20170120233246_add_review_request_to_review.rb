class AddReviewRequestToReview < ActiveRecord::Migration[5.0]
  def change
    add_reference :reviews, :review_request, null: true
  end
end
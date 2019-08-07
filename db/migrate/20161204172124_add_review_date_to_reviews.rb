class AddReviewDateToReviews < ActiveRecord::Migration[5.0]
  def change
    add_column :reviews, :review_date, :datetime, null: true
    add_column :reviews, :publish_date, :datetime, null: true

    Review.all.each do |review|
      review.update_attributes(review_date: review.updated_at)
      review.update_attributes(publish_date: review.updated_at) if review.published?
    end
  end
end
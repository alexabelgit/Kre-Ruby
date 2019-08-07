class ReviewReviewable < ApplicationRecord

  belongs_to :review,                        touch: true, inverse_of: :review_reviewables
  belongs_to :reviewable, polymorphic: true, touch: true

end

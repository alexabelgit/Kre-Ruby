class ImportedReviewRequestProduct < ApplicationRecord

  belongs_to :imported_review_request
  belongs_to :product

  validates_uniqueness_of :product_id, scope: :imported_review_request_id

  # TODO ~ maybe we could use transaction items instead of these, and relink them to real review requests afterwords?

end

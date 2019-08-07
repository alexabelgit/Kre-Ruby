class ImportedReviewRequest < ApplicationRecord
  belongs_to :customer

  has_many :imported_review_request_products, dependent: :destroy
  has_many :products, through: :imported_review_request_products

  delegate :store, to: :customer
  delegate :display_name, to: :customer

  scope :latest, -> { order(scheduled_for: :desc) }

end

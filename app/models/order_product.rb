class OrderProduct < ApplicationRecord
  belongs_to :order, touch: true
  belongs_to :product, touch: true

  has_one :review,         dependent: :destroy
  has_one :customer,       through: :order
  has_one :review_request, through: :order

  has_many :emails, through: :review_request

  after_commit :verify_questions
  after_save   :check_product_suppression

  validates_uniqueness_of :order_id, scope: :product_id

  scope :with_reviews,       -> { left_outer_joins(:review).where.not(reviews: { id: nil }) }
  scope :without_reviews,    -> { left_outer_joins(:review).where(reviews: { id: nil }) }
  scope :with_sent_requests, -> { joins(:review_request).merge(ReviewRequest.sent) }

  scope :by_review_requests, -> (order_product) { includes(:review_request).order("order_products.id = #{order_product.id} DESC,
                                                                                   review_requests.id = #{order_product&.review_request&.id || 0} DESC,
                                                                                   order_products.created_at DESC") }

  def will_produce_repeated_review?
    # Returning nil if review is present because order_product will not produce
    # anything else. This means it could have already produced a repeated review
    # and this method does not tell us about it
    customer.reviewed_products.where(id: product_id).any? unless review.present?
  end

  private

  def verify_questions
    self.product.questions.map(&:verify)
  end

  def check_product_suppression
    self.destroy if self.product.suppressed
  end
end

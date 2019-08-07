class TransactionItem < ApplicationRecord
  belongs_to :order,          optional: true,    touch: true
  belongs_to :review_request, optional: true,    touch: true
  belongs_to :reviewable,     polymorphic: true, touch: true
  belongs_to :customer,                          touch: true

  has_one :self_ref, class_name: self.name, foreign_key: :id # To use product directly (although it is in polymorphic Assosiaction), this ugly hack seems to be needed
  has_one :product,  through: :self_ref,    source: :reviewable, source_type: Product.name
  has_one :business, through: :self_ref,    source: :reviewable, source_type: Store.name

  has_one :review

  has_many :emails, through: :review_request

  delegate :store, to: :customer

  after_create_commit :verify_questions

  validates :order,          presence: true, unless: :review_request
  validates :review_request, presence: true, unless: :order

  validates_uniqueness_of :order_id,          scope: [:reviewable_id, :reviewable_type], allow_nil: true
  validates_uniqueness_of :review_request_id, scope: [:reviewable_id, :reviewable_type], allow_nil: true

  scope :with_reviews,               -> { left_outer_joins(:review).where.not(reviews: { id: nil }) }
  scope :without_reviews,            -> { left_outer_joins(:review).where(reviews: { id: nil }) }
  scope :with_sent_requests,         -> { joins(:review_request).merge(ReviewRequest.sent) }

  scope :with_products,              -> { where(reviewable_type: Product.name) }
  scope :without_products,           -> { where.not(reviewable_type: Product.name) }
  scope :with_unsuppressed_products, -> { left_outer_joins(:product).where('products.suppressed = FALSE OR NOT transaction_items.reviewable_type = ?', Product.name) }

  scope :by_review_requests,         -> ( transaction_item ) { includes(:review_request).order("transaction_items.id = #{transaction_item.id} DESC,
                                                                                        review_requests.id = #{transaction_item&.review_request&.id || 0} DESC,
                                                                                        transaction_items.created_at DESC") }
  scope :with_orders,                -> { where.not(order: nil) }
  scope :without_orders,             -> { where(order: nil) }
  scope :with_review_requests,       -> { where.not(review_request: nil) }
  scope :without_review_requests,    -> { where(review_request: nil) }

  def will_produce_repeated_review?
    # Returning nil if review is present because transaction_item will not produce
    # anything else. This means it could have already produced a repeated review
    # and this method does not tell us about it
    customer.reviewed_products.where(id: reviewable_id).any? && reviewable_type == Product.name unless review.present?
  end

  private

  def verify_questions
    product.questions.where(customer: customer).map(&:verify) if product.present?
  end

  def check_product_suppression
    destroy if reviewable.class == Product && reviewable.suppressed
  end
end

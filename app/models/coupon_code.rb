class CouponCode < ApplicationRecord
  belongs_to :discount_coupon
  has_many   :review_request_coupon_codes, dependent: :destroy

  validates_presence_of :code

  scope :free, -> { left_outer_joins(:review_request_coupon_codes).where(review_request_coupon_codes: { id: nil }) }
  scope :used, -> { joins(:review_request_coupon_codes).where.not(review_request_coupon_codes: { id: nil }) }
  scope :latest, -> { order(created_at: :desc) }
  scope :oldest, -> { order(created_at: :asc) }
  scope :current, -> { where(current: true) }

  scope :by_usage_number, -> { left_outer_joins(:review_request_coupon_codes).group(:id).order('COUNT(review_request_coupon_codes.id) DESC').order(code: :desc) }

  def make_current
    update_attributes(current: true)
  end

  def unmake_current
    update_attributes(current: false)
  end

  def status
    review_request_coupon_codes.any? ? 'used' : 'pending'
  end

  def review_request
    review_request_coupon_codes.first.review_request if review_request_coupon_codes.any?
  end

  def customer
    review_request.customer if review_request.present?
  end

end

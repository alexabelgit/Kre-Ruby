class ReviewRequestCouponCode < ApplicationRecord
  include Filterable

  belongs_to :review_request
  belongs_to :coupon_code

  searchkick word_start: [:coupon_name, :promotion_name, :code, :customer_email, :discount],
             highlight:  [:coupon_name, :promotion_name, :code, :customer_email, :discount],
             callbacks:  :async

  scope :search_import, -> {
    includes(coupon_code: { discount_coupon: :promotions })
    .includes(review_request: :customer)
  }

  scope :latest, -> { order(created_at: :desc) }

  def search_data
    {
      coupon_name:    coupon_code.discount_coupon.name,
      promotion_name: coupon_code.discount_coupon.promotions.first&.name,
      customer_email: review_request.customer.email,
      code:           coupon_code.code,
      discount:       coupon_code.discount_coupon.discount_text,
      created_at:     created_at,
      store_id:       review_request.store.id
    }
  end

  def self.search_fields
    [:coupon_name, :promotion_name, :code, :customer_email, :discount]
  end

  def self.sort_mapper
    {
      latest: { created_at: { order: :desc, unmapped_type: :long } }
    }
  end

end

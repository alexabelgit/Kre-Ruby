class PromotionDiscountCoupon < ApplicationRecord
  belongs_to :promotion,       inverse_of: :promotion_discount_coupons
  belongs_to :discount_coupon, inverse_of: :promotion_discount_coupons
end

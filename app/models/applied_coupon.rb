class AppliedCoupon < ApplicationRecord
  belongs_to :bundle
  belongs_to :coupon
end

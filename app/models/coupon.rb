class Coupon < ApplicationRecord
  belongs_to :ecommerce_platform

  has_many :applied_coupons, dependent: :destroy
  has_many :bundles, through: :applied_coupons
end

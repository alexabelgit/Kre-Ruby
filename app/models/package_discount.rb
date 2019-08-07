class PackageDiscount < ApplicationRecord
  include Deprecatable

  belongs_to :ecommerce_platform

  has_many :applied_discounts, dependent: :destroy
  has_many :bundles, through: :applied_discounts

  validates :discount_percents, numericality: { greater_than: 0 }

  def self.bundle_discount(bundle)
    addons_count = bundle.addon_prices.size

    find_by ecommerce_platform: bundle.platform,
            addons_count: addons_count
  end
end

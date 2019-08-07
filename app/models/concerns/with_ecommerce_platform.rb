module WithEcommercePlatform
  extend ActiveSupport::Concern

  included do
    belongs_to :ecommerce_platform

    scope :shopify, -> { where(ecommerce_platform: EcommercePlatform.shopify) }
    scope :ecwid, -> { where(ecommerce_platform: EcommercePlatform.ecwid) }
    scope :custom, -> { where(ecommerce_platform: EcommercePlatform.custom)}
  end
end

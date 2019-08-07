class PaymentProcessor
  SHOPIFY = 'shopify'.freeze
  CHARGEBEE = 'chargebee'.freeze

  PROCESSING_PLATFORMS = {
    shopify:    SHOPIFY,
    ecwid:      CHARGEBEE,
    lemonstand: CHARGEBEE,
    custom:     CHARGEBEE
  }.freeze

  def self.processing_platform(ecommerce_platform)
    PROCESSING_PLATFORMS.fetch ecommerce_platform.name, default_platform
  end

  def self.chargebee?(store)
    platform = processing_platform(store.ecommerce_platform)
    platform == CHARGEBEE
  end

  def self.default_platform
    CHARGEBEE
  end
end

class Plan < ApplicationRecord
  has_many :bundle_items, as: :price_entry

  include Priceable
  include Deprecatable
  include WithEcommercePlatform

  include Comparable

  enum pricing_model: {
         orders: 'orders',
         products: 'products'
       }

  before_create :add_slug

  def self.latest_price(ecommerce_platform)
    latest.find_by ecommerce_platform: ecommerce_platform
  end

  def self.helpful(store)
    pricing_model = store.pricing_model || :products
    where(ecommerce_platform: store.ecommerce_platform, slug: 'helpful', pricing_model: pricing_model).latest.first
  end

  def self.shopify_affiliate
    where(ecommerce_platform: EcommercePlatform.shopify, slug: 'affiliate').latest.first
  end

  def self.latest_timestamp
    maximum(:updated_at)
  end

  def products_based?
    pricing_model == :products
  end

  def orders_based?
    pricing_model == :orders
  end

  def add_slug
    self.slug = name.parameterize.underscore if slug.blank?
  end

  def <=>(other_plan)
    return 1 if price_in_cents.nil?
    return -1 if other_plan.price_in_cents.nil?
    price_in_cents <=> other_plan.price_in_cents
  end

  def same?(other_plan)
    slug == other_plan.slug && self == other_plan
  end

  def extension_price_in_dollars
    in_dollars extension_price_in_cents
  end

  def extensible?
    extension_price_in_cents.present?
  end

  # currently applies only for Shopify
  def overages_limit
    limit_in_cents = overages_limit_in_cents || Rails.configuration.billing.default_overages_limit
    in_dollars limit_in_cents
  end

  def affiliate?
    slug == 'affiliate'
  end
end

class Addon < ApplicationRecord
  include AASM

  has_many :addon_prices, dependent: :destroy

  enum state: {
         disabled: 0,
         active: 1,
         beta: 2
  }

  aasm :column => :state, :enum => true do
    state :disabled, initial: true
    state :active, :beta

    event :publish do
      transitions from: [:disabled, :beta] , to: :active
    end

    event :disable do
      transitions from: [:active, :beta], to: :disabled
    end

    event :launch_beta do
      transitions from: [:active, :disabled], to: :beta
    end
  end

  before_create :add_slug

  def add_slug
    self.slug = name.parameterize.underscore unless slug
  end

  def self.product_groups
    find_by slug: 'product_groups'
  end

  def self.[](name)
    find_by name: name
  end

  def shopify_price
    latest_price(EcommercePlatform.shopify)&.price_in_dollars
  end

  def ecwid_price
    latest_price(EcommercePlatform.ecwid)&.price_in_dollars
  end

  def latest_price(ecommerce_platform)
    addon_prices.latest.where(ecommerce_platform: ecommerce_platform).first
  end
end

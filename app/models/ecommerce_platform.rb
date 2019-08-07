class EcommercePlatform < ApplicationRecord
  has_many :coupons,           dependent: :destroy
  has_many :package_discounts, dependent: :destroy

  has_many :addon_prices,      dependent: :destroy
  has_many :plans,             dependent: :destroy

  has_many :stores

  SUPPORTED_PLATFORMS = %w(ecwid shopify lemonstand custom).freeze
  ANONYMIZATION_WORKER_DELAY = {default: 1.year, shopify: 1.minute}

  SUPPORTED_PLATFORMS.each do |name|
    define_method("#{name}?") { self.name == name }
  end

  class << self
    SUPPORTED_PLATFORMS.each do |name|
      define_method("#{name}") { find_or_create_by name: name }
    end
  end

  def slug
    name.to_sym
  end
end

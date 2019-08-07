module Addons
  module PersistAddon
    extend ActiveSupport::Concern

    included do
      string :name, default: nil
      string :slug, default: nil
      string :description, default: nil
      string :state, default: nil

      hash :prices, default: nil do
        float :shopify
        float :ecwid
      end
    end

    def new_price_command
      AddonPrices::SetNewAddonPrice
    end

    protected

    def update_addon_prices(addon, prices)
      return unless prices
      prices.each do |platform_name, price|
        ecommerce_platform = EcommercePlatform.find_by name: platform_name
        inputs = { ecommerce_platform: ecommerce_platform, price: price, addon: addon }
        compose new_price_command, inputs
      end
    end
  end
end

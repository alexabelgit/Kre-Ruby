module AddonPrices
  class SetNewAddonPrice < ApplicationCommand
    object :ecommerce_platform
    object :addon
    float :price

    def execute
      price_in_cents = to_cents price
      params = { addon: addon, ecommerce_platform: ecommerce_platform, price_in_cents: price_in_cents }

      current_price = addon.latest_price(ecommerce_platform)
      set_new_price current_price, params
    end

    private

    def set_new_price(current_price, new_price_params)
      addon_price = nil
      ActiveRecord::Base.transaction do
        current_price.deprecate! if current_price
        addon_price = AddonPrice.create! new_price_params
      end
      addon_price
    rescue ActiveRecord::StatementInvalid => e
      errors.add(:addon_price, e.message)
    end

    def to_cents(price)
      (price * 100).to_i
    end
  end
end

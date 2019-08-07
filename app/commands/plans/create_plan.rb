module Plans
  class CreatePlan < ApplicationCommand
    record :ecommerce_platform

    string :name

    integer :price_in_cents
    string :pricing_model, default: 'products'

    string :description

    integer :min_products_limit, default: nil
    integer :max_products_limit, default: nil

    integer :orders_limit, default: nil

    integer :extension_price_in_cents, default: nil
    integer :extended_orders_limit, default: nil

    integer :overages_limit_in_cents, default: nil

    string :chargebee_id, default: nil

    date_time :deprecated_at, default: nil
    boolean :popular, default: false

    boolean :is_secret, default: false


    def execute
      plan = Plan.new inputs

      if plan.save
        deprecate_old_prices plan
      else
        errors.merge!(plan.errors)
      end

      plan
    end

    def to_model
      Plan.new ecommerce_platform: EcommercePlatform.shopify,
               overages_limit_in_cents: Rails.configuration.billing.default_overages_limit
    end

    private

    def deprecate_old_prices(new_price)
      same_plan_prices = Plan.where(ecommerce_platform: ecommerce_platform,
                                    pricing_model: plan.pricing_model,
                                    name: name)
                             .where.not(id: new_price)
      same_plan_prices.each(&:deprecate!)
    end
  end
end

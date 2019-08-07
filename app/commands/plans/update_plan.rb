module Plans
  class UpdatePlan < ApplicationCommand
    object :plan

    record :ecommerce_platform, default: nil

    string :name, default: nil
    string :description

    integer :price_in_cents, default: nil

    integer :min_products_limit, default: nil
    integer :max_products_limit, default: nil

    integer :orders_limit, default: nil

    integer :extension_price_in_cents, default: nil
    integer :extended_orders_limit, default: nil

    integer :overages_limit_in_cents, default: nil

    string :chargebee_id, default: nil

    boolean :popular, default: nil
    boolean :is_secret, default: nil

    def to_model
      plan
    end

    def execute
      plan.assign_attributes given_inputs.except(:plan)

      errors.merge!(plan.errors) unless plan.save
      plan
    end
  end
end

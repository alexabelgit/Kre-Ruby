module Bundles
  class CreateBundle < ApplicationCommand
    object :store

    boolean :preselect_plan, default: false

    def execute
      bundle = Bundle.create store: store

      if bundle.persisted?
        set_default_plan(bundle) if preselect_plan
      end
      bundle
    end

    def set_default_plan(bundle)
      plan = Plan.latest.where(ecommerce_platform: bundle.platform).first
      if plan.blank?
        add_plan_not_found_error
      else
        BundleItem.create bundle: bundle, price_entry: plan
      end
    end

    def add_plan_not_found_error
      if Rails.env.development?
        errors.add(:plan, 'is not found for this platform.')
      else
        errors.add(:plan, '^Please contact us to resolve this issue.')
      end
    end
  end
end

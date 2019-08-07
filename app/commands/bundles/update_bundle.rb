module Bundles
  class UpdateBundle < ApplicationCommand
    object :bundle
    string :plan_id
    array :addon_price_ids, default: []

    def execute
      change_plan
      update_addons if bundle.addons_enabled?

      bundle.reload
    end

    private

    def change_plan
      return if bundle.plan_record&.id == plan_id
      plan = Plan.find_by id: plan_id

      if plan
        bundle.bundle_items.where(price_entry_type: 'Plan').destroy_all
        BundleItem.create bundle: bundle, price_entry: plan
      end
    end

    def update_addons
      remove_excluded_addons
      add_new_addons
    end

    def remove_excluded_addons
      bundle.bundle_items
        .where.not(price_entry_id: addon_price_ids)
        .where(price_entry_type: 'AddonPrice' )
        .destroy_all
    end

    def add_new_addons
      existing_addon_price_ids = bundle.addon_prices.pluck(:id)

      addon_prices_to_add = AddonPrice.where(id: addon_price_ids).where.not(id: existing_addon_price_ids)

      addon_prices_to_add.each do |ap|
        BundleItem.create bundle: bundle, price_entry: ap
      end
    end
  end
end

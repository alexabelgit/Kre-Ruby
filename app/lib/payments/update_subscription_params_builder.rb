module Payments
  class UpdateSubscriptionParamsBuilder

    def initialize(new_bundle, old_bundle)
      @new_bundle = new_bundle
      @old_bundle = old_bundle
    end

    def prepare_params
      store = new_bundle.store
      if store.addons_feature_enabled?
        plan_and_addons_change
      else
        only_plan
      end
    end

    def only_plan
      new_plan_id = new_bundle.plan_record.chargebee_id
      { plan_id: new_plan_id }
    end

    def plan_and_addons_change
      plan_id = new_bundle.plan_record.chargebee_id
      addons = new_bundle.addons.pluck(:chargebee_id).map do |id|
        { id: id }
      end

      { plan_id: plan_id, addons: addons }
    end

    # use this when you want to select only upgrade subset of bundle changes
    # useful when you want to prorate upgraded changes and schedule downgrade
    def upgrade_params
      params = {}

      plan_id = changed_plan_id { |new_price, old_price| new_price > old_price }
      params[:plan_id] = plan_id if plan_id

      addon_params = build_addon_upgrade_params
      params[:addons] = addon_params if addon_params

      params
    end

    # use this when you want to select only downgrade subset of bundle changes
    # useful when you want to prorate upgraded changes and schedule downgrade
    def downgrade_params
      params = {}

      plan_id = changed_plan_id { |new_price, old_price| new_price < old_price }
      params[:plan_id] = plan_id if plan_id

      new_addons = new_bundle.addon_prices.pluck(:chargebee_id)
      params[:addons] = new_addons.map { |chargebee_id| { id: chargebee_id } }
      params
    end

    private
    attr_reader :old_bundle, :new_bundle

    def changed_plan_id
      old_bundle_plan = old_bundle.plan_record
      new_bundle_plan = new_bundle.plan_record

      return if new_bundle_plan.same?(old_bundle_plan)
      return unless yield(new_bundle.plan_price, old_bundle.plan_price)
      new_bundle_plan.chargebee_id
    end

    def build_addon_upgrade_params
      platform = new_bundle.platform

      new_addons = new_bundle.addons.pluck(:slug)
      old_addons = old_bundle.addons.pluck(:slug)

      addons_difference = new_addons - old_addons

      return if addons_difference.blank?

      addons = Addon.where(slug: addons_difference)
      prices = AddonPrice.where(ecommerce_platform: platform, addon: addons).latest.pluck(:chargebee_id)

      prices.map { |chargebee_id| { id: chargebee_id } }
    end
  end
end

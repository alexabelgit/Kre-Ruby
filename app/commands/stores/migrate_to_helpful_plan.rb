module Stores
  class MigrateToHelpfulPlan < ApplicationCommand
    object :store

    def execute
      if store.subscription?
        errors.add(:store, 'Migration of store with active subscription to Helpful plan is not supported yet' )
        return store
      end

      helpful_plan = Plan.helpful(store)

      if helpful_plan.nil?
        errors.add(:plan, 'Could not find Helfpul plan for this store ecommerce platform')
        return store
      end

      create_helpful_plan_subscription(helpful_plan)
      start_billing_for_store
    end

    private

    def start_billing_for_store
      compose StartBilling, store: store
    end

    def create_helpful_plan_subscription(helpful_plan)
      bundle = Bundle.create store: store, state: :processing
      BundleItem.create bundle: bundle, price_entry: helpful_plan
      processing_platform = store.shopify? ? 'shopify' : 'chargebee'
      next_billing_at = 1.month.from_now

      Subscription.create bundle: bundle,
                          state: :active,
                          last_payment_at: DateTime.current,
                          expired_at: next_billing_at,
                          next_billing_at: next_billing_at,
                          billing_interval: 'month',
                          processing_platform: processing_platform,
                          gifted: true
      bundle.activate!
    end
  end
end
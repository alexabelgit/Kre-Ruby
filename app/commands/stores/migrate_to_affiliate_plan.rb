module Stores
  class MigrateToAffiliatePlan < ApplicationCommand
    object :store

    def execute
      if store.subscription?
        errors.add(:store, 'Migration of store with active subscription to Affiliate plan is not supported yet' )
        return store
      end

      unless store.shopify?
        errors.add(:store, 'Affiliate plan available only for Shopify stores')
        return store
      end

      affiliate_plan = Plan.shopify_affiliate

      if affiliate_plan.nil?
        errors.add(:store, 'Could not find affiliate plan, please contact us')
        return store
      end

      create_affiliate_plan_subscription(affiliate_plan)
    end

    def create_affiliate_plan_subscription(affiliate_plan)
      bundle = Bundle.create store: store, state: :processing
      BundleItem.create bundle: bundle, price_entry: affiliate_plan
      processing_platform = 'shopify'
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
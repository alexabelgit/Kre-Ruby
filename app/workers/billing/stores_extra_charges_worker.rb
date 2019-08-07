require 'sidekiq-scheduler'

module Billing
  class StoresExtraChargesWorker
    include Sidekiq::Worker
    sidekiq_options queue: :high

    # TODO: replace with subscription billing interval
    BILLING_INTERVAL = 1.month.freeze

    def perform
      StoreSubscriptionUsage.refresh

      stores_to_check = Store.with_active_subscription
                          .merge(Subscription.at_the_end_of_billing_cycle)
      stores_to_check.each do |store|
        next unless store.charge_extra_orders?
        subscription = store.active_subscription
        Subscriptions::ChargeExtras.run subscription: subscription
        renew_subscription(subscription) if store.shopify? || subscription.gifted?
      end
    end

    def renew_subscription(subscription)
      return unless subscription.active?
      next_billing_at = (subscription.next_billing_at + BILLING_INTERVAL).to_datetime

      Subscriptions::RenewSubscription.run subscription: subscription, next_billing_at: next_billing_at, updated_at: DateTime.current
    end
  end
end

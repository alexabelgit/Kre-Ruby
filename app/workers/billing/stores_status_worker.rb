require 'sidekiq-scheduler'

module Billing
  class StoresStatusWorker
    include Sidekiq::Worker
    sidekiq_options queue: :default

    EXPIRATION_GRACE_INTERVAL = 10.minutes

    def perform
      process_recently_expired_trials
      cancel_expired_subscriptions
    end

    private

    def cancel_expired_subscriptions
      expired_subscriptions = Subscription.non_renewing.where('expired_at < ?', EXPIRATION_GRACE_INTERVAL.from_now)
      expired_subscriptions.find_each do |subscription|
        Subscriptions::ChangeSubscriptionState.run subscription: subscription, state: :cancelled
      end
    end

    def process_recently_expired_trials
      interval = 7.days.ago..DateTime.current
      stores = Store.where(trial_ends_at: interval)
                    .where('deactivated_at IS NULL')
                    .includes(bundles: :subscription)

      stores.find_each do |store|
        next if store.subscription?
        if store.shopify?
          Stores::MigrateToHelpfulPlan.run store: store
        else
          store.update deactivated_at: store.trial_ends_at
        end
      end
    end
  end
end

class StoresStatusJob < ApplicationJob
  queue_as :default

  ### SIDEKIQED

  EXPIRATION_GRACE_INTERVAL = 10.minutes

  def perform
    deactivate_stores_with_trial_expired
    cancel_expired_subscriptions
  end

  private

  def cancel_expired_subscriptions
    expired_subscriptions = Subscription.non_renewing.where('expired_at < ?', EXPIRATION_GRACE_INTERVAL.from_now)
    expired_subscriptions.find_each do |subscription|
      Subscriptions::ChangeSubscriptionState.run subscription: subscription, state: :cancelled
    end
  end

  # we just set deactivation date here
  # store still continues to be active during "grace period"
  def deactivate_stores_with_trial_expired
    stores = Store.where('trial_ends_at < ?', Time.current).where('deactivated_at IS NULL')
    stores.find_each do |store|
      store.update deactivated_at: store.trial_ends_at
    end
  end
end

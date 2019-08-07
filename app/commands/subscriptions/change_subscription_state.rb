module Subscriptions
  class ChangeSubscriptionState < ApplicationCommand
    object :subscription

    symbol :state

    def execute
      case state
      when :active
        subscription.activate!
        subscription.bundle&.activate!
        reset_store_deactivation
        reactivate_store_front_and_back
      when :suspended
        subscription.suspend!
        subscription.bundle&.disable!
      when :pending
        subscription.await_acceptance!
        subscription.bundle&.mark_as_processing!
      when :reactivating
        subscription.await_reactivation!
        subscription.bundle&.mark_as_processing!
      when :non_renewing
        subscription.stop_renewal!
      when :cancelled
        subscription.cancel!
        subscription.bundle&.outdate!
      when :failed
        if subscription.reactivating?
          subscription.update state: :cancelled
          subscription.bundle&.outdate!
        else
          subscription.fail!
          subscription.bundle&.fail!
        end
      end
      refresh_subscription_usage_view
    end

    private

    def reset_store_deactivation
      store = subscription.store
      return unless store.deactivation_date?

      compose(Stores::ResetDeactivation, store: store)
    end

    def reactivate_store_front_and_back
      return if subscription.gifted?
      subscription.store.update status: :active, storefront_status: :active
    end

    def refresh_subscription_usage_view
      StoreSubscriptionUsage.refresh
    end
  end
end

module Stores
  class UninstallStore < ApplicationCommand
    object :store

    def execute
      attributes = {
        access_token:   nil,
        status:         'inactive',
        installed_at:   nil,
        uninstalled_at: DateTime.current
      }
      result = store.update attributes
      if result
        stop_all_subscriptions
        clean_up_bundles
      end
      store
    end

    private

    def stop_all_subscriptions
      return unless store.can_be_billed? && store.subscription?

      compose Subscriptions::CancelSubscription, subscription: store.active_subscription, stop_recurring_charges: true
    end

    def clean_up_bundles
      store.bundles.where.not(state: [:draft, :active, :outdated])
    end
  end
end

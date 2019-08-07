module Users
  class DeactivateUser < ApplicationCommand
    object :user

    def execute
      return if user.deleted?
      user.update_attribute(:deleted_at, Time.current)

      store = user.store

      deactivate_store(store) if store.present?

      user
    end

    def deactivate_store(store)
      store.update deactivated_at: DateTime.current
      store.inactive!
      store.storefront_inactive!

      if store.subscription?
        subscription = store.active_subscription
        if subscription.gifted?
          Subscriptions::AbortSubscription.run subscription: subscription
        else
          Subscriptions::CancelSubscription.run subscription: subscription, stop_recurring_charges: true, cancellation_reason: 'user deactivated'
        end
      end

      delay = store.shopify? ? EcommercePlatform::ANONYMIZATION_WORKER_DELAY[:shopify] : EcommercePlatform::ANONYMIZATION_WORKER_DELAY[:default]
      AnonymizeCustomersWorker.perform_in(delay, store.id)
      DeleteImagesWorker.perform_in(90.days, store.id)
    end
  end
end

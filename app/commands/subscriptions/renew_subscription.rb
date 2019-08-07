module Subscriptions
  class RenewSubscription < ApplicationCommand
    object :subscription

    date_time :updated_at
    date_time :next_billing_at

    def execute
      update_subscription
      reset_order_tracking_emails
      StoreSubscriptionUsage.refresh
    end

    private

    def update_subscription
      inputs = { subscription: subscription,
                 updated_at: updated_at,
                 next_billing_at: next_billing_at,
                 expired_at: next_billing_at,
                 state: :active
               }

      compose Subscriptions::UpdateSubscription, inputs
    end

    def reset_order_tracking_emails
      store = subscription.store
      store.update_settings :billing,
                            plan_exceeded_email_sent: false,
                            plan_exceeding_email_sent: false
    end
  end
end

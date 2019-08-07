module Subscriptions
  class ClearDebt < ApplicationCommand
    object :subscription

    def execute
      result = subscription.update due_since: nil,
                                   total_due: 0,
                                   due_invoices_count: 0,
                                   dunning_start_date: nil,
                                   dunning_end_date: nil

      if subscription.cancelled?
        Payments::RecurringCharge.build(subscription).reactivate if subscription.cancelled?
        compose Subscriptions::ChangeSubscriptionState, subscription: subscription, state: :active
      end
    end
  end
end

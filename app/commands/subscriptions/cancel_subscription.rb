module Subscriptions
  class CancelSubscription < ApplicationCommand
    object :subscription
    boolean :stop_recurring_charges, default: false
    boolean :cancelled_by_customer, default: true
    date_time :cancelled_at, default: nil
    string :cancellation_reason, default: nil

    integer :total_due, default: nil
    date_time :due_since, default: nil
    integer :due_invoices_count, default: nil

    def execute
      if subscription.may_cancel?
        payments_service.cancel if stop_payments?

        update_subscription_fields subscription
        (cancelled_by_customer && !shopify?) ? stop_renewal : cancel_immediately

        Result.new success: true, status: :subscription_cancelled
      else
        errors.add(:subscription, 'cannot be cancelled')
        subscription
      end
    end

    def payments_service
      Payments::RecurringCharge.build subscription
    end

    private

    def stop_payments?
      cancelled_by_customer && stop_recurring_charges && subscription.real?
    end

    def shopify?
      subscription.store.shopify?
    end

    def cancel_immediately
      subscription.update(expired_at: subscription.cancelled_on)
      compose ChangeSubscriptionState, subscription: subscription, state: :cancelled
    end

    def stop_renewal
      compose ChangeSubscriptionState, subscription: subscription, state: :non_renewing
    end

    def update_subscription_fields(subscription)
      cancelled_on = cancelled_at || DateTime.current
      subscription.cancelled_on = cancelled_on
      subscription.cancellation_reason = cancellation_reason if cancellation_reason?

      if subscription.cancellation_reason == 'non_paid'
        subscription.dunning_end_date = cancelled_on
        subscription.due_since = due_since
        subscription.due_invoices_count = due_invoices_count
        subscription.total_due = total_due
      end
      subscription.save
    end
  end
end

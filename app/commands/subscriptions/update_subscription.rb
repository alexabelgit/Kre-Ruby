module Subscriptions
  class UpdateSubscription < ApplicationCommand
    object :subscription
    object :chargebee_customer, default: nil
    object :bundle, default: nil

    symbol :state, default: nil

    string :id_from_provider, default: nil
    string :hosted_page_id, default: nil
    date_time :accepted_on, default: nil
    date_time :activated_on, default: nil
    date_time :cancelled_on, default: nil
    date_time :next_billing_at, default: nil
    date_time :last_payment_at, default: nil
    string :billing_interval, default: nil
    date_time :expired_at, default: nil

    def execute
      compose(ChangeSubscriptionState, subscription: subscription, state: state) if state?

      subscription.assign_attributes changed_attributes

      unless subscription.save
        errors.merge!(subscription.errors)
      end
      subscription
    end

    private

    def changed_attributes
      { id_from_provider: id_from_provider,
        hosted_page_id: hosted_page_id,
        accepted_on: accepted_on,
        activated_on: activated_on,
        cancelled_on: cancelled_on,
        next_billing_at: next_billing_at,
        expired_at: expired_at,
        billing_interval: billing_interval,
        last_payment_at: last_payment_at,
        chargebee_customer: chargebee_customer,
        bundle: bundle
      }.compact
    end
  end
end

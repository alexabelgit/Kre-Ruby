module Subscriptions
  class ConfirmShopifySubscription < ApplicationCommand
    object :subscription

    delegate :store, to: :subscription

    def execute
      result = Payments::RecurringCharge.build(subscription).activate

      if result.success?
        attributes = extract_subscription_params result
        inputs = attributes.merge(subscription: subscription)

        compose update_subscription_command, inputs
        cancel_previous_active_subscriptions
        compose Stores::StartBilling, store: store

      else
        errors.add(:charge, result.error_message )
        subscription
      end
    end

    def update_subscription_command
      Subscriptions::UpdateSubscription
    end

    def cancel_subscription_command
      Subscriptions::CancelSubscription
    end

    private

    def notify_user
      BackMailer.subscription_changed(store.id).deliver
    end


    def cancel_previous_active_subscriptions
      other_active_subscriptions = store.subscriptions.where.not(id: subscription).active
      other_active_subscriptions.each do |subscription|
        compose cancel_subscription_command, subscription: subscription, cancelled_at: DateTime.current
      end
    end

    def extract_subscription_params(result)
      charge = result.entity
      Shopify::PaymentResultParser.new(charge).to_attributes
    end
  end
end

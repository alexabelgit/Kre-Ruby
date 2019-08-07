module Subscriptions
  class ReactivateSubscription < ApplicationCommand
    object :bundle
    object :subscription

    def execute
      return if bundle.platform.shopify?

      bundle.mark_as_processing!

      user = bundle.store.user
      Payments::RecurringCharge.build(subscription).remove_scheduled_cancellation

      if subscription.initial_bundle
        if same_plan?(subscription.initial_bundle)
          renew_subscription_with_new_bundle
        else
          renew_subscription_and_switch_to_new_plan
        end
      else
        if same_plan?(subscription.bundle)
          renew_subscription_with_same_bundle
        else
          renew_subscription_and_switch_to_new_plan
        end
      end
    end

    private

    def renew_subscription_with_new_bundle
      subscription.bundle.outdate!
      bundle.activate!

      compose Subscriptions::UpdateSubscription, subscription: subscription, state: :active, bundle: bundle
      DataStruct.new platform: :chargebee, subscription: subscription, action: :renew
    end

    def renew_subscription_with_same_bundle
      bundle.outdate!
      compose Subscriptions::UpdateSubscription, subscription: subscription, state: :active
      DataStruct.new platform: :chargebee, subscription: subscription, action: :renew
    end

    def renew_subscription_and_switch_to_new_plan
      compose Subscriptions::ChangeSubscription, bundle: bundle, current_subscription: subscription, initial_bundle: subscription.initial_bundle
      DataStruct.new platform: :chargebee, subscription: subscription, action: :renew_and_change
    end

    def same_plan?(old_bundle)
      return false unless old_bundle
      old_plan = old_bundle.plan_record

      new_plan = bundle.plan_record
      old_plan.same? new_plan
    end
  end
end

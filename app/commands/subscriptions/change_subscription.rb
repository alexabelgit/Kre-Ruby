module Subscriptions
  # changes active subscription at the end of term
  # new bundle is added as next_bundle and replaces current at the end of term
  # not applicable for shopify since we just replace subscription for it
  class ChangeSubscription < ApplicationCommand
    object :bundle
    object :current_subscription, class: Subscription
    object :initial_bundle, class: Bundle, default: nil

    def execute
      unless bundle.may_mark_as_processing?
        errors.add(:bundle, 'cannot be processed when it is not in pending state')
        return
      end

      bundle.mark_as_processing!

      upgrade_chargebee_subscription
      update_bundle_and_subscription
      notify_user

      DataStruct.new platform: :chargebee, action: :update, subscription: current_subscription
    end

    private

    def notify_user
      store = bundle.store
      BackMailer.subscription_changed(store.id).deliver
    end

    def upgrade_chargebee_subscription
      recurring_charge_service.remove_scheduled_changes(current_subscription) if switching_to_initial_plan?(current_subscription)

      params_builder = Payments::UpdateSubscriptionParamsBuilder.new(bundle, old_bundle)
      update_params = params_builder.prepare_params
      recurring_charge_service.update_subscription_with_deferred_invoice update_params
    end

    def update_bundle_and_subscription
      current_subscription.initial_bundle = current_subscription.bundle if current_subscription.initial_bundle.blank?

      current_subscription.bundle.outdate!
      bundle.activate!

      current_subscription.bundle = bundle
      current_subscription.state = :active if current_subscription.terminating?
      current_subscription.save

      StoreSubscriptionUsage.refresh
    end

    def recurring_charge_service
      @recurring_charge_service ||= Payments::RecurringCharge.build(current_subscription)
    end

    def switching_to_initial_plan?(subscription)
      initial_plan = subscription.initial_bundle&.plan_record
      return false if initial_plan.nil?

      new_plan = bundle.plan_record
      new_plan.same? initial_plan
    end

    def old_bundle
      initial_bundle || current_subscription.bundle
    end
  end
end

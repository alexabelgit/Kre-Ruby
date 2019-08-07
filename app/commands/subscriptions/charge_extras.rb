module Subscriptions
  class ChargeExtras < ApplicationCommand
    object :subscription

    def execute
      if need_to_charge_plan?
        charge_plan_difference
        reset_plan_changed_flag
      end

      charge_over_quota_usage if need_to_charge_overages?
    end

    private

    def payment_already_made?(payment_type)
      subscription.payments_within_billing_cycle(payment_type: payment_type).present?
    end

    def need_to_charge_plan?
      subscription.chargebee? && subscription.live? && subscription.changed_during_billing_cycle? && !payment_already_made?('upgrade')
    end

    def need_to_charge_overages?
      store = subscription.store
      store.charge_extra_orders? && !payment_already_made?('overages')
    end

    def charge_plan_difference
      old_plan = subscription.initial_bundle.plan_record
      current_plan = subscription.bundle.plan_record
      charge = Plan::UpgradeCharge.new(new_plan: current_plan, previous_plan: old_plan)

      return unless charge&.amount&.positive?

      result = recurring_charge.charge_extras(charge.amount, charge.description)
      create_payment result, 'upgrade'
    end

    def reset_plan_changed_flag
      subscription.update initial_bundle_id: nil
    end

    def charge_over_quota_usage
      charge = Plan::OverageCharge.new subscription

      return unless charge.amount.positive?

      result = recurring_charge.charge_extras charge.amount, charge.description
      create_payment result, 'overages'
    end

    def create_payment(charge_result, payment_type)
      payment_params = charge_result.to_h.slice(:amount, :description, :id_from_provider)
      payment_params.merge!(payment_type: payment_type,
                            payment_made_at: DateTime.current,
                            store: subscription.store)
      subscription.payments.create payment_params
    end

    def recurring_charge
      @recurring_charge ||= Payments::RecurringCharge.build(subscription)
    end
  end
end

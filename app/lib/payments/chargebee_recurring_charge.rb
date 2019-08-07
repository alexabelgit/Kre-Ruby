require 'chargebee'

module Payments
  class ChargebeeRecurringCharge < RecurringCharge

    # Current cancellation options:
    # * cancel at the end of term
    # * do not return credits on cancellation
    # * invoice all unbilled charges immediately
    # * try to collect all 'due' charges
    def cancel
      ChargeBee::Subscription.cancel subscription.id_from_provider,
                                     end_of_term: true,
                                     credit_option_for_current_term_charges: :none,
                                     unbilled_charges_option: :invoice,
                                     account_receivables_handling: :schedule_payment_collection
    end

    def charge_extras(amount, description)
      params = {
        amount: amount,
        description: description
      }
      result = ChargeBee::Subscription.add_charge_at_term_end subscription.id_from_provider, params

      payment_id = fetch_payment_id result.estimate, amount, description

      OpenStruct.new amount: amount, description: description, id_from_provider: payment_id
    end

    def remove_scheduled_changes(subscription)
      return unless scheduled_changes?(subscription)

      ChargeBee::Subscription.remove_scheduled_changes subscription.id_from_provider
    end

    def remove_scheduled_cancellation
      ChargeBee::Subscription.remove_scheduled_cancellation subscription.id_from_provider
    end

    def reactivate
      ChargeBee::Subscription.reactivate subscription.id_from_provider
    end

    # always replace addons list completely
    # defer prorated charges till next billing cycle
    # give credits for charged but cancelled addons
    def update_subscription_with_deferred_invoice(updated_params)
      updated_params.merge! end_of_term: true,
                            invoice_immediately: true,
                            replace_addon_list: true
      ChargeBee::Subscription.update subscription.id_from_provider, updated_params
    end

    private

    def fetch_payment_id(subscription_estimate, amount, description)
      payments = subscription_estimate.invoice_estimate.line_items

      payment = payments.first { |payment| payment.amount == amount && payment.description == description }
      payment&.id
    end

    def scheduled_changes?(subscription)
      response = ChargeBee::Subscription.retrieve subscription.id_from_provider
      response.subscription&.has_scheduled_changes.to_b
    end
  end
end

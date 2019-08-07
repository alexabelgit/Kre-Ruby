module Payments
  class ChargebeeHostedPage
    attr_reader :hosted_page

    delegate :id, :as_json, :content, to: :hosted_page

    def initialize(hosted_page)
      @hosted_page = hosted_page
    end

    def self.retrieve(hosted_page_id)
      return nil unless hosted_page_id

      result = ChargeBee::HostedPage.retrieve(hosted_page_id)
      return nil if result.blank?

      new(result.hosted_page)
    end

    def self.build(user, bundle, subscription)
      # TODO: probably we won't have cancelled
      reactivate = subscription.cancelled? || subscription.terminating?

      hosted_page_params = Payments::HostedPageParams.new(user, bundle, subscription, reactivate: reactivate)
      checkout_params = hosted_page_params.checkout_params

      result = build_checkout_page subscription, checkout_params
      new(result.hosted_page)
    end

    def handle_submission
      subscription = Subscription.find_by hosted_page_id: id

      case hosted_page.state
      when 'succeeded'
        acknowledge_page
        deprecate_gifted_subscription subscription
        outcome = confirm_subscription subscription
        if outcome.valid?
          OpenStruct.new status: :confirmed, result: outcome.result
        else
          OpenStruct.new status: :error, errors: outcome.errors
        end
      when 'requested'
        outcome = rollback_failed_subscription subscription
        OpenStruct.new status: :rolled_back, result: outcome.result, errors: outcome.errors
      else
        OpenStruct.new status: :nothing_changed, result: subscription
      end
    end

    def acknowledge_page
      ChargeBee::HostedPage.acknowledge hosted_page.id
    end

    private

    def deprecate_gifted_subscription(subscription)
      store = subscription.store
      if store.active_subscription&.gifted?
        Subscriptions::AbortSubscription.run subscription: store.active_subscription
      end
    end

    def self.build_checkout_page(subscription, checkout_params)
      if subscription.cancelled?
        ChargeBee::HostedPage.checkout_existing(checkout_params)
      else
        ChargeBee::HostedPage.checkout_new(checkout_params)
      end
    end

    def confirm_subscription(subscription)
      inputs = { subscription: subscription,
                 subscription_info: subscription_attributes,
                 customer_info: customer_attributes,
                 payment_method_info: payment_method_attributes,
                 card_info: card_attributes
               }
      Subscriptions::ConfirmChargebeeSubscription.run inputs
    end

    def rollback_failed_subscription(subscription)
      inputs = { subscription: subscription, state: :failed }
      Subscriptions::ChangeSubscriptionState.run inputs
    end

    def subscription_attributes
      subscription = content.subscription
      {
        id_from_provider: subscription.id,
        activated_on: Time.at(subscription.activated_at).to_datetime,
        next_billing_at: Time.at(subscription.next_billing_at).to_datetime,
        billing_interval: subscription.billing_period_unit,
      }
    end

    def customer_attributes
      customer = content.customer
      {
        id_from_provider: customer.id,
        email: customer.email,
        first_name: customer.first_name,
        last_name: customer.last_name
      }
    end

    def payment_method_attributes
      customer = content.customer
      payment_type = customer.payment_method.type
      {
        processing_platform: 'chargebee',
        customer_id: customer.id,
        id_from_provider: customer.primary_payment_source_id,
        payment_type: payment_type
      }
    end

    def card_attributes
      return nil if content.card.blank?
      card = Chargebee::ResponseParser.to_hash content.card
      card.slice(:card_type, :masked_number, :expiry_month, :expiry_year)
    end
  end
end

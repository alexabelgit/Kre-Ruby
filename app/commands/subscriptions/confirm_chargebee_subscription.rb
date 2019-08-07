module Subscriptions
  class ConfirmChargebeeSubscription < ApplicationCommand
    object :subscription

    hash :subscription_info do
      string :id_from_provider
      date_time :activated_on
      date_time :next_billing_at
      string :billing_interval
    end

    hash :customer_info do
      string :id_from_provider
      string :email
      string :first_name, default: nil
      string :last_name, default: nil
    end

    hash :payment_method_info do
      string :id_from_provider
      string :processing_platform
      string :payment_type
    end

    hash :card_info, default: nil do
      string :card_type, default: nil
      string :masked_number, default: nil
      integer :expiry_month, default: nil
      integer :expiry_year, default: nil
    end

    def execute
      customer = find_or_create_customer
      payment_method = find_or_create_payment_method customer

      params = {
        subscription: subscription,
        state: :active,
        chargebee_customer: customer,
        hosted_page_id: '' ,
        expired_at: subscription_info[:next_billing_at]
      }

      subscription_params = subscription_info.merge(params)

      compose Subscriptions::UpdateSubscription, subscription_params
      compose Stores::StartBilling, store: subscription.store
      subscription
    end

    private

    def find_or_create_customer
      customer = ChargebeeCustomer.find_by id_from_provider: customer_info[:id_from_provider]

      if customer.blank?
        attributes = customer_info.dup
        attributes[:store] = subscription.store
        customer = ChargebeeCustomer.create attributes
      end
      customer
    end

    def find_or_create_payment_method(customer)
      payment_method = PaymentMethod.find_by id_from_provider: payment_method_info[:id_from_provider], chargebee_customer: customer

      if payment_method.blank?
        payment_method_attributes = payment_method_info.dup
        if paid_with_card?
          payment_method_attributes.merge! card_info
        end
        payment_method_attributes[:chargebee_customer_id] = customer.id
        PaymentMethod.create payment_method_attributes
      end
    end

    def paid_with_card?
      payment_method_info[:payment_type] == 'card' && card_info.present?
    end
  end
end

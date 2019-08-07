module Shopify
  class PaymentResultParser

    PAYMENT_STATES_MAP = {
      "pending" => :pending,
      "accepted" => :processing,
      "active" => :active,
    }.freeze

    delegate :activated_on, to: :payment_result

    def initialize(payment_result)
      @payment_result = payment_result
    end

    def state
      payment_status_to_state payment_result.status
    end

    def id_from_provider
      payment_result.id.to_s
    end

    def next_billing_at
      1.month.from_now.to_datetime
    end

    def to_attributes
      { activated_on:     activated_on,
        id_from_provider: id_from_provider,
        next_billing_at:  next_billing_at,
        state:            state }.compact
    end

    private

    attr_reader :payment_result

    def payment_status_to_state(status)
      PAYMENT_STATES_MAP.fetch(status, nil)
    end
  end
end

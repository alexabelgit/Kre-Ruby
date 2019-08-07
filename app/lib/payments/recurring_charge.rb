module Payments
  class RecurringCharge
    attr_reader :subscription

    def initialize(subscription)
      @subscription = subscription
    end

    def self.build(subscription)
      case subscription.processing_platform
      when 'shopify'
        ShopifyRecurringCharge.new(subscription)
      when 'chargebee'
        ChargebeeRecurringCharge.new(subscription)
      else
        ChargebeeRecurringCharge.new(subscription)
      end
    end

    def cancel
      raise 'Abstract class method called'
    end
  end
end

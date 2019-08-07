class Plan
  class OverageCharge
    include Priceable
    attr_reader :plan

    def initialize(subscription)
      @subscription = subscription
      @plan = ActivePlan.new(subscription)
    end

    def orders_over_quota
      return 0 unless valid?

      @orders_over_quota ||= count_orders_over_quota
    end

    def amount
      return 0 unless valid?
      return 0 if plan.extension_amount.zero?
      bundles = (orders_over_quota / plan.extension_amount.to_f).ceil
      bundles * plan.extension_price
    end

    def description
      return '' unless valid?

      charged = in_dollars_as_currency amount
      "#{charged} for #{orders_over_quota} orders over plan limit"
    end

    private

    attr_reader :subscription

    def valid?
      plan.present? && plan.extensible?
    end

    def count_orders_over_quota
      store = subscription.store

      total_orders = store.orders_in_current_billing_cycle

      over_quota = total_orders - store.orders_quota
      [over_quota, 0].max
    end
  end
end

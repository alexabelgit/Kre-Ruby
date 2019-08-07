module Admin
  class SubscriptionChargesPresenter
    attr_reader :subscription, :v
    include Priceable

    delegate :plan_price, to: :subscription

    def initialize(subscription, view = ActionView::Base.new)
      @subscription = subscription
      @v = view
    end

    def billing_date
      v.humane_date subscription.next_billing_at
    end

    def store_name
      subscription.store.name
    end

    def store_id
      subscription&.store&.to_param
    end

    def total_charge
      (plan_price + overage_charge + upgrade_charge).round(2)
    end

    def overage_charge
      charge = Plan::OverageCharge.new subscription
      in_dollars(charge.amount)
    end

    def upgrade_charge
      return 0 unless subscription.initial_bundle
      old_plan = subscription.initial_bundle.plan_record
      current_plan = subscription.bundle.plan_record
      charge = Plan::UpgradeCharge.new(new_plan: current_plan, previous_plan: old_plan)
      in_dollars(charge.amount)
    end
  end
end

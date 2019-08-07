class ActivePlan
  include Priceable
  attr_reader :store, :subscription, :plan


  delegate :name, :description, :orders_limit,
           :is_secret?, :extensible?, :extended_orders_limit,
           :affiliate?, :overages_limit,
           :max_products_limit, :min_products_limit,
           :pricing_model,
           to: :plan,
           allow_nil: true

  alias_method :plan_allowance, :orders_limit

  def initialize(subscription)
    @subscription = subscription
    @plan = find_active_plan
  end

  def self.for_store(store)
    new store.active_subscription
  end

  def plan_price
    in_dollars plan.price_in_cents
  end
  alias_method :price_in_dollars, :plan_price

  def extension_price
    plan&.extension_price_in_cents
  end

  def extensible?
    extension_price&.positive? && extension_amount&.positive?
  end

  def extension_price_in_dollars
    in_dollars extension_price
  end

  def extension_amount
    plan&.extended_orders_limit
  end

  private

  def find_active_plan
    return nil if subscription.nil?
    return subscription.bundle.plan_record if subscription.initial_bundle.nil?

    old_plan = subscription.initial_bundle.plan_record
    new_plan = subscription.bundle.plan_record

    # if we downgraded - we calculate quota and overages based on previous higher plan
    # otherwise we use higher plan immediately
    new_plan < old_plan ? old_plan : new_plan
  end
end
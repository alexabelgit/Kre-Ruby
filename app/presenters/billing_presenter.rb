require 'chargebee'

class BillingPresenter
  attr_reader :store, :view, :active_plan

  delegate :trial?,
           :grace_period?,
           :trial_ending?,
           :trial_ended?,
           :days_left_on_trial,
           :dunning_failed?,
           :paid?,
           :terminating?,
           :can_be_billed?,
           :next_payment_date,
           :next_payment_date?,
           :subscription?,
           :cancelled?,
           :latest_cancelled_subscription,
           :trial_ends_at,
           :orders_based_billing?,
           :products_based_billing?,
           :shopify?,
           to: :store

  def initialize(store, view_context = ActionView::Base.new)
    @store = store
    @view  = view_context
    @active_plan = ActivePlan.for_store(@store)
  end

  def plan_price
    view.number_to_currency(active_plan.plan_price) || draft_bundle_presenter.plan_price
  end

  def plan_name
    active_plan&.name || draft_bundle_presenter.plan_name
  end

  def plan_orders_limit
    active_plan&.orders_limit || draft_bundle_presenter.orders_limit
  end

  def chargebee?
    PaymentProcessor.chargebee?(store)
  end

  def addons_enabled?
    store.addons_feature_enabled?
  end

  def chargebee_site
    ChargeBee.default_env.site
  end

  def subscription_cancelled?
    return false if store.subscription?
    store.latest_cancelled_subscription.present?
 end

  def cancellation_date
    return '' unless subscription_cancelled?

    view.humane_date store.latest_cancelled_subscription.cancelled_on
  end

  def subscription_expires_at
    subscription = active_subscription || store.latest_cancelled_subscription
    date = subscription&.expired_at
    return '' unless date

    view.humane_date date
  end

  def trial_expires_at
    date = store.trial_ends_at

    view.humane_date date
  end

  def draft_bundle_presenter
    bundle = store.draft_bundle
    BundlePresenter.new bundle, view
  end

  def upgrade_bundle_presenter
    bundle = store.draft_bundle
    old_bundle = store.active_bundle
    UpgradeBundlePresenter.new bundle, old_bundle, view
  end

  def active_bundle_presenter
    bundle = active_subscription&.bundle
    BundlePresenter.new bundle, view
  end

  def current_bundle_presenter
    BundlePresenter.new current_bundle, view
  end

  def current_subscription_presenter
    CurrentSubscriptionPresenter.new(self)
  end

  def trial_presenter
    TrialPresenter.new(self)
  end

  def available_plans
    pricing_model = store.pricing_model || 'products'
    pricing_model == 'products' ? products_based_plans : orders_based_plans
  end

  def gifted_products
    active_subscription&.gifted_products
  end

  def gifted_products?
    gifted_products.positive?
  end

  def products_limit_without_gifts
    return nil unless active_plan.max_products_limit

    active_plan.max_products_limit
  end

  def products_based_plans
    plans = Plan.latest.where(ecommerce_platform: store.ecommerce_platform,
                                           is_secret: false, pricing_model: :products)
                                    .order('price_in_cents ASC').to_a


    active_products_count = store.active_products_count

    chargeable_products_count = subscription? ? [active_products_count - gifted_products, 0].max : active_products_count

    most_suitable_index = plans.find_index do |plan|
      plan.min_products_limit <= chargeable_products_count && (plan.max_products_limit.nil? || plan.max_products_limit >= chargeable_products_count )
    end

    default_suggested_index = plans.find_index do |plan|
      plan.min_products_limit <= active_products_count && (plan.max_products_limit.nil? || plan.max_products_limit >= active_products_count )
    end

    indexes = if most_suitable_index.zero?
                (0..2) # first three plans
              elsif most_suitable_index == plans.size - 1
                [most_suitable_index-1, most_suitable_index]
              else
                (most_suitable_index - 1..most_suitable_index + 1)
              end
    indexes.map do |index| PlanPresenter.new plans[index], self,
                                             suggested: index == most_suitable_index,
                                             gifted_products: gifted_products,
                                             suggested_without_gifts: default_suggested_index == index
    end
  end

  def orders_based_plans
    plans = Plan.latest.where(ecommerce_platform: store.ecommerce_platform,
                      is_secret: false,
                      pricing_model: :orders)
                .order('price_in_cents ASC')
    plans.map { |plan| PlanPresenter.new plan, self }
  end

  def plan_css_classes(plan)
    classes = ""
    classes << "active"   if active_bundle_presenter.current_plan?(plan)
    classes << 'selected' if draft_bundle_presenter.current_plan?(plan)
    classes
  end

  def billing_history?
    can_be_billed? && !(trial? || grace_period?)
  end

  def registered_at
    store.created_at.to_s(:long)
  end

  def trial_until
    view.humane_date store.trial_ends_at
  end

  def retry_subscription?
    return false unless subscription?

    active_subscription&.pending? || active_subscription&.error?
  end

  def subscription_id
    subscription = active_subscription || store.latest_cancelled_subscription
    subscription&.id
  end

  def manage_subscription?
    chargebee? && (paid? || terminating? || dunning_failed?)
  end

  def subscription_state
    active_subscription&.state
  end

  def hide_when_subscribed_class
    subscription? ? 'hidden' : ''
  end

  def cancelled_plan_name
    bundle = store.latest_cancelled_subscription.bundle
    bundle&.plan_name
  end

  def cancelled_addons
    bundle = store.latest_cancelled_subscription.bundle
    bundle&.addons
  end

  def current_plan_name
    if store.subscription?
      active_plan.name
    elsif store.has_debt?
      'Payment failed'
    elsif store.subscription_expired? || store.trial_ended?
      'No active plan'
    elsif store.trial?
      'Trial'
    end
  end

  def current_plan_extensible?
    active_plan.extensible?
  end

  def current_plan_allowance
    active_plan.plan_allowance
  end

  def customer_id
    return if !paid? || !chargebee?
    active_subscription&.customer_id
  end

  def payment_method
    return if trial? || cancelled? || !active_subscription || active_subscription&.gifted?

    case active_subscription.processing_platform
    when 'shopify'
      'Shopify billing'
    when 'chargebee'
      'Credit card'
    else
      ''
    end
  end

  def card_icon(card_type)
    case card_type
    when 'visa'
      view.hc_icon 'cc-visa', class: 'billing__card-icon'
    when 'mastercard'
      view.hc_icon 'cc-mastercard', class: 'billing__card-icon'
    end
  end

  def active_bundle
    store.active_bundle
  end

  def draft_bundle
    store.draft_bundle
  end

  def active_subscription
    active_bundle&.subscription
  end

  private

  def current_bundle
    active_bundle || draft_bundle
  end
end

class CurrentSubscriptionPresenter
  include Priceable

  attr_reader :view, :presenter

  delegate :store,
           :current_plan_name, :plan_price,
           :subscription_id,
           :current_plan_extensible?,
           :payment_method, :next_payment_date?, :next_payment_date,
           :subscription_cancelled?, :cancellation_date, :manage_subscription?,
           :products_based_billing?, :orders_based_billing?,
           :gifted_products, :gifted_products?, :products_limit_without_gifts,
           to: :presenter

  delegate :has_addons?,
           :addon_count,
           :enabled_addons,
           to: :bundle_presenter

  delegate :paid?, :terminating?,
           :trial_ended?, :trial_ending?, :trial?, :total_trial_duration,
           :dunning?, :dunning_failed?,
           :days_left_on_trial, :withheld?,
           :next_payment_date?, :plan_exceeded?,
           to: :store

  def initialize(billing_presenter)
    @presenter = billing_presenter
    @view      = billing_presenter.view
  end

  def bundle_presenter
    presenter.current_bundle_presenter
  end

  def active_subscription?
    store.subscription? && store.active_subscription.active?
  end

  def real_subscription?
    store.active_subscription&.real?
  end

  def charge_extras?
    store.charge_extra_orders?
  end

  def expired?
    store.subscription_expired?
  end

  def subscription_expired_at
    presenter.subscription_expires_at
  end

  def trial_expired_at
    presenter.trial_expires_at
  end

  def orders_plan_usage
    return 0 unless presenter.active_subscription
    store.orders_in_current_billing_cycle
  end

  def products_plan_usage
    store.products_amount
  end

  def orders_plan_allowance
    Rails.cache.fetch [store, 'orders_limit_in_billing_cycle'] do
      store.active_subscription&.orders_limit_in_billing_cycle
    end
  end

  def products_plan_allowance
    Rails.cache.fetch [store, 'products_limit_in_billing_cycle'] do
      store.active_subscription&.products_limit_in_billing_cycle || 'Unlimited'
    end
  end

  def plan_usage_percent
    store.quota_percent
  end

  def orders_plan_usage_vs_allowance
    "<strong>#{orders_plan_usage}</strong> of <strong>#{orders_plan_allowance}</strong> in-plan orders".html_safe
  end

  def products_plan_usage_vs_allowance
    "You have <strong>#{products_plan_usage}</strong> active products of <strong>#{products_plan_allowance}</strong> available in your plan.".html_safe
  end

  def products_plan_over_limit_message
    return nil unless store.plan_exceeded?

    "You have exceeded your allowance of active products. Reviews for out-of-plan products will not be collected and displayed.\
    Consider upgrading to a higher value plan"
  end

  def orders_plan_usage_message
    case plan_usage_percent
    when 0...80
      nil
    when 80...100
      orders_left = orders_plan_allowance - orders_plan_usage
      orders_word = 'order'.pluralize(orders_left)
      "You have only #{orders_left} in-plan #{orders_word} remaining"
    when 100
      "You have reached your monthly allowance of in-plan orders and \
       additional orders will be charged at the out-of-plan order rate"
    else
      if current_plan_extensible?
        "You are now being charged for out-of-plan orders. Consider upgrading \
         to a higher value plan"
      else
        "You have exceeded your allowance of in-plan orders and need to \
         upgrade to a higher plan"
      end
    end
  end

  def orders_plan_usage_state
    case plan_usage_percent
    when 0...80
      'success'
    when 80...100
      'warning'
    else
      'danger'
    end
  end

  def total_debt
    view.number_to_currency in_dollars(-store.total_debt)
  end

  def next_payment_date_long
    return '' unless next_payment_date?
    date = view.humane_date store.next_payment_date
    "Recurring charge: #{date}"
  end

  def trial_ending_in
    days = view.pluralize(days_left_on_trial, 'days')
    "Ending in #{days}"
  end

  def trial_active_for
    days = "days".pluralize(days_left_on_trial)
    "Active for #{days_left_on_trial} more #{days} "
  end

  def addons_amount
    view.pluralize addon_count, 'add-on', 'add-ons'
  end
end

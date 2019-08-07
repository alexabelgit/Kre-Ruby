class StoreTrialPresenter
  include Priceable

  delegate :user_email, :can_be_billed?, :shopify?, to: :store

  def initialize(store, view_context = ActionView::Base.new)
    @store        = store
    @view_context = view_context
  end

  def total_trial_duration
    store.total_trial_duration.inspect
  end

  def formatted_trial_name
    intervals = total_trial_duration.split
    if intervals.size == 2 # ["30", "days"] => "30-day"
      quantity, measure = intervals
      measure = measure.singularize
      "#{quantity}-#{measure}"
    else # ["1", "year", "and", 3", "months"] => "1 year and 3 months long"
      "#{total_trial_duration} long"
    end
  end

  def trial_expiring_in
    days = Store::DAYS_BEFORE_TRIAL_ENDS_TO_NOTIFY_USER
    view_context.pluralize(days, 'day')
  end

  def plan_price
    price_in_dollars = in_dollars store.plan_price
    view_context.number_to_currency price_in_dollars
  end

  def helpful_plan_orders_limit
    Plan.helpful(store)&.orders_limit
  end

  def user_first_name
    store.user.first_name
  end

  private

  attr_reader :store, :view_context
end

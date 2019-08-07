class BundlePresenter
  include Priceable

  delegate :id, to: :bundle, prefix: true, allow_nil: true

  delegate :enabled_addons,
           :has_addons?,
           :summary,
           :total_price,
           :plan_name,
           :plan_record,
           to: :bundle,
           allow_nil: true

  def initialize(bundle, view)
    @bundle = bundle
    @view   = view
  end

  def present?
    bundle.present?
  end

  def discount
    view.number_to_currency in_dollars(bundle.discount_amount)
  end

  def discounted?
    bundle.discount_amount.positive?
  end

  def price
    view.number_to_currency bundle.dollars_price
  end

  def raw_price
    view.number_to_currency in_dollars(bundle.raw_price)
  end

  def plan_price
    view.number_to_currency in_dollars(bundle.plan_price)
  end

  def current_plan?(plan)
    return false unless bundle
    bundle.plan_name == plan.name
  end

  def plan_orders_limit
    bundle.plan_orders_limit
  end

  def addon_count
    bundle.addon_prices.size
  end

  private

  attr_reader :bundle, :view
end

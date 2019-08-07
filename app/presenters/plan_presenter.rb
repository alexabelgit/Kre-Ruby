class PlanPresenter
  attr_reader :plan, :presenter, :suggested, :gifted_products

  delegate :view,
           :paid?,
           :terminating?,
           :products_based_billing?,
           :orders_based_billing?,
           to: :presenter

  delegate :name, :id, to: :plan

  def initialize(plan, presenter, options = {})
    @plan      = plan
    @presenter = presenter
    @suggested = options[:suggested]
    @gifted_products = options[:gifted_products] || 0
  end


  def gifted_products_message?
    suggested && gifted_products.positive?
  end


  def price
    if negotiable?
      view.content_tag :div, class: 'plan__price-negotiable' do
        "Need a custom plan? <br> Let's build it together".html_safe
      end
    else
      view.content_tag(:span, view.number_to_currency(plan.price_in_dollars), class: 'plan__price-in-dollars') +
      " / Mo".html_safe
    end
  end

  def product_limits
    if plan.min_products_limit.zero?
      "For stores that have less than #{plan.max_products_limit} products"
    elsif plan.max_products_limit.nil?
      view.content_tag :div do
        view.concat view.content_tag(:p, "For stores with more than #{plan.min_products_limit} products")
        view.concat(view.content_tag(:div) do
          view.concat view.content_tag(:sup, '*')
          view.concat view.content_tag(:span, " subject to our ")
          view.concat view.content_tag(:a, "Fair Usage Policy",  href: fair_usage_policy_url, target: '_blank')
        end
        )
      end
    else
      "For stores with #{plan.min_products_limit} to #{plan.max_products_limit} products"
    end
  end

  def products_limits_with_gifted_products
    "We suggest you this plan because you have your products limit increased by #{gifted_products} as a gift from us"
  end

  def orders_quota
    if plan.orders_limit
      result = "<strong>#{plan.orders_limit}</strong> in-plan orders"
      result.html_safe
    end
  end

  def extension
    if plan.extensible?
      price  = view.number_to_currency plan.in_dollars(plan.extension_price_in_cents)
      result = "#{plan.extended_orders_limit} out-of-plan orders for #{price}"
      result.html_safe
    end
  end

  def negotiable?
    plan.price_in_cents.nil?
  end

  def popular?
    return false unless fresh_subscription?
    plan.popular?
  end

  def suggested?
    suggested
  end

  def fresh_subscription?
    !(paid? || terminating?)
  end

  def active?
    status == 'active'
  end

  def renewable?
    status == 'renewable'
  end

  def status
    active_plan = presenter.active_bundle_presenter.plan_record

    if active_plan.present?
      return 'renewable'  if terminating? && plan == active_plan
      return 'active'     if plan.same?(active_plan)
      return 'negotiable' if negotiable? # This needs to be AFTER active_plan check
                                         # so that if negotiable plan is active, we show this properly
      if products_based_billing?
        'switchable'
      else
        plan > active_plan ? 'upgradable' : 'downgradable'
      end
    else
      negotiable? ? "negotiable" : "subscribable"
    end
  end

  def call_to_action
    if active?
      active_call_to_action
    elsif renewable?
      renew_subscription_call_to_action
    elsif negotiable?
      negotiable_call_to_action
    else
      new_subscription_call_to_action
    end
  end

  def call_to_action_behavior
    negotiable? ? '' : 'subscribe'
  end

  private

  def active_call_to_action
    result = view.content_tag :div, class: 'plan__c2a plan__c2a--active' do
      view.hc_icon('check') + " Subscribed"
    end
    result.html_safe
  end

  def renew_subscription_call_to_action
    result = view.content_tag :div, class: "plan__c2a plan__c2a--renewable" do
      'Renew'
    end
    result.html_safe
  end

  def negotiable_call_to_action
    result =
      view.content_tag :div, class: 'plan__c2a plan__c2a--lets-talk' do
        content =  "Contact us via <br>".html_safe
        content << view.chat_trigger('chat')
        content << " or "
        content << view.mail_to(ENV['BILLING_EMAIL'], 'email', target: '_blank')
      end
    result.html_safe
  end

  def new_subscription_call_to_action
    result = view.content_tag :div, class: "plan__c2a plan__c2a--#{status}" do
      case status
      when 'upgradable'
        'Upgrade'
      when 'downgradable'
        'Downgrade'
      when 'switchable'
        'Activate'
      else 'Subscribe'
      end
    end
    result.html_safe
  end

  def fair_usage_policy_url
    ENV['FAIR_USAGE_POLICY_URL']
  end
end

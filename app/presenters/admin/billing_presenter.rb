module Admin
  class BillingPresenter
    include Priceable
    attr_reader :store, :view

    delegate :days_left_on_trial, :trial_ends_at,
             :total_grace_period, :can_be_billed?,
             :subscription?, :active_subscription,
             :active_bundle,
             :orders_based_billing?, :products_based_billing?,
             :products_amount,
             :paid?, :trial?, :grace_period?,
             to: :store

    def initialize(store, view_context = ActionView::Base.new)
      @store = store
      @view  = view_context
    end

    def trial_until
      view.humane_date store.trial_ends_at
    end

    def registered_at
      store.created_at.to_s(:long)
    end

    def products_quota
      return 'Unlimited' if store.products_quota.nil?

      from_plan = ActivePlan.for_store(store).max_products_limit
      gifted = store.active_subscription.gifted_products
      "#{store.products_quota} ( Plan: #{from_plan}, gifted: #{gifted} )"
    end

    def subscription_state
      active_subscription&.state
    end

    def monthly_charge
      return view.number_to_currency(0) unless active_bundle

      bundle_presenter = BundlePresenter.new active_bundle, view
      bundle_presenter.price
    end

    def gifted?
      active_bundle&.subscription&.gifted?
    end

    def chargebee_subscription?
      active_subscription&.chargebee?
    end

    def subscription_provider_id
      active_subscription&.id_from_provider
    end

    def next_billing_at
      view.humane_date active_subscription&.next_billing_at
    end

    def orders_and_quota
      orders = store.orders_in_current_billing_cycle
      quota = store.orders_quota

      color = orders > quota ? 'red' : 'black'
      "<span style='color: #{color}'>#{orders} of #{quota}</span>".html_safe
    end

    def overages
      charge = Plan::OverageCharge.new active_subscription
      view.number_to_currency in_dollars(charge.amount)
    end

    def billing_status
      if paid? || gifted?
        active_bundle&.summary
      elsif trial?
        "Trial: #{days_left_on_trial} days left"
      elsif grace_period?
        grace_period_finishes = trial_ends_at + total_grace_period
        "On grace period: ends on #{grace_period_finishes.to_s(:short)}"
      else
        "Trial expired on #{trial_ends_at.to_s(:short)}"
      end
    end
  end
end

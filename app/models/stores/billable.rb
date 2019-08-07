module Stores
  module Billable
    extend ActiveSupport::Concern

    PLAN_EXCEEDING_START = 80
    PLAN_EXCEEDED_START = 100

    included do
      has_one :store_subscription_usage
      has_one :store_products_usage

      scope :trial_ended, -> { where('trial_ends_at < ?', Time.current) }

      enum pricing_model: {
          orders: 'orders',
          products: 'products'
      }

      scope :with_products_based_billing, -> { where(pricing_model: 'products') }
      scope :with_orders_based_billing, -> { where(pricing_model: 'orders') }

      def has_plan(plan)
        all.joins(bundles: :bundle_items).merge(BundleItem.where(price_entry: plan))
      end
    end

    def orders_based_billing?
      pricing_model == 'orders'
    end

    def products_based_billing?
      pricing_model == 'products'
    end

    def orders_amount(time_range)
      orders.where(order_date: time_range).count
    end

    def products_amount; active_products_count; end;

    def orders_in_current_billing_cycle
      Rails.cache.fetch [self, 'orders_in_current_billing_cycle'] do
        orders = store_subscription_usage&.orders_amount
        return orders if orders.present?

        return 0 unless subscription?
        orders_amount(active_subscription.current_billing_cycle)
      end
    end

    def quota_percent
      Rails.cache.fetch [self, 'store_quota_percent'] do
        if orders_based_billing?
          return 0 unless subscription?
          orders_in_current_billing_cycle.percent_of orders_quota
        else
          return 0 if products_amount.nil?
          products_amount.percent_of products_quota
        end
      end
    end

    def products_quota
      active_subscription.products_limit_in_billing_cycle
    end

    def orders_quota
      store_subscription_usage&.orders_limit || active_subscription.orders_limit_in_billing_cycle
    end

    def plan_exceeding?
      return false if products_based_billing? # plan exceeding not needed for products based billing

      can_be_billed? && real_subscription? && (80...100).cover?(quota_percent)
    end

    def plan_exceeded?
      billable = can_be_billed? && subscription?
      return false unless billable

      if products_based_billing?
        products_quota.present? ? products_amount > products_quota : false
      else
        quota_percent > 100
      end
    end

    def should_upgrade?
      return false unless plan_exceeded?

      active_subscription.plan_extensible?
    end

    def must_upgrade?
      return false unless plan_exceeded?

      !active_subscription.plan_extensible?
    end

    def can_be_billed?
      Flipper[:billing].enabled?(self)
    end

    # check if extra charges enabled for store first
    # for Helpful plan subscriptions always prompt to upgrade
    # For active paid customers - wait for next billing cycle after launch to start charging overages
    def charge_extra_orders?
      return false if products_based_billing?

      return false unless Flipper[:orders_tracking].enabled?(self)
      return false if active_subscription.nil?
      active_subscription.real?
    end

    def subscription?
      active_subscription.present?
    end

    def real_subscription?
      subscription? && active_subscription.real?
    end

    def dunning?
      subscription? && active_subscription.dunning?
    end

    def dunning_failed?
      !subscription? && has_debt?
    end

    def latest_cancelled_subscription
      subscriptions.cancelled.order('cancelled_on DESC').first
    end

    def has_debt?
      subscriptions.cancelled.where('total_due > 0').present?
    end

    def total_debt
      subscriptions.sum(:total_due)
    end

    def next_payment_date?
      can_be_billed? && paid? && !shopify? &&
        !gifted? && !dunning? && next_payment_date.present?
    end

    def next_payment_date
      active_subscription.next_billing_at
    end

    def live?
      return true unless can_be_billed?

      trial? || grace_period? || (active_subscription.present? && active_subscription.live?)
    end

    def gifted?
      active_subscription.present? && active_subscription.gifted?
    end

    def paid?
      active_subscription.present? && !active_subscription.terminating? && !gifted?
    end

    def terminating?
      active_subscription&.terminating?&.to_b
    end

    def trial?
      never_paid? && !trial_ended? && !terminating?
    end

    def grace_period?
      never_paid? && trial_ended? && !grace_period_ended?
    end

    def suspended?
      return false unless can_be_billed?

      (never_paid? && grace_period_ended?) || subscription_expired?
    end

    def subscription_expired?
      had_subscription_before? && !active_subscription&.live?
    end

    def grace_period_ended?
      trial_ends_at <= Store::GRACE_PERIOD_DAYS.days.ago
    end

    # Returns true if store is on trial and trial is ending soon
    def trial_ending?
      return false unless trial?

      trial_ends_at <= Store::DAYS_BEFORE_TRIAL_ENDS_TO_NOTIFY_USER.days.from_now
    end

    def trial_ended?
      return true if trial_ends_at.nil?

      trial_ends_at <= Time.current
    end

    def withheld?
      subscription? && active_subscription.gifted? && active_subscription.withheld?
    end

    def days_left_on_trial
      # Returns positive or negative number of days from trial_ends_at date
      days_left = (trial_ends_at - Time.current) / 1.day
      days_left.ceil
    end

    def total_trial_duration
      if Flipper[:extended_trial].enabled?(self)
        Rails.configuration.billing.extended_trial_duration
      else
        Rails.configuration.billing.default_trial_duration
      end
    end

    def total_grace_period
      Store::GRACE_PERIOD_DAYS.days
    end

    def excluded_from_trial_emails?
      !can_be_billed? || paid? || gifted? || user.deleted?
    end

    def never_paid?
      !(paid? || had_subscription_before? || gifted?)
    end

    def cancelled?
      return false if live?

      had_subscription_before? && latest_cancelled_subscription.present? && !has_debt?
    end

    def billing_status
      return 'cancelled'      if cancelled?
      return 'dunning_failed' if dunning_failed?
      return 'dunning'        if dunning?
      return 'affiliate'      if subscription? && active_subscription.affiliate?
      return 'active'         if subscription?
      return 'grace_period'   if grace_period?
      return 'trial_ended'    if grace_period_ended?
      return 'trial'          if trial?
    end

    def deactivation_date?
      deactivated_at.present?
    end

    private

    def start_trial
      self.trial_started_at = Time.current
      self.trial_ends_at    = trial_started_at + total_trial_duration unless trial_ends_at
    end
  end
end

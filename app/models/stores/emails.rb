module Stores
  module Emails
    extend ActiveSupport::Concern

    included do
      before_create :start_trial

      scope :plan_emails_not_suspended, -> { where(plan_emails_suspended: false) }

      scope :need_send_trial_ending_email, -> {
        time_range = Store::DAYS_BEFORE_TRIAL_ENDS_TO_NOTIFY_USER.days.from_now.all_day
        where(trial_ends_at: time_range)
          .includes(:bundles, :setting_objects, :user)
          .reject(&:excluded_from_trial_emails?)
          .reject(&:trial_ending_email_sent?)
      }

      scope :need_send_trial_finished_email, -> {
        where('trial_ends_at < ?', Time.current)
          .includes(:setting_objects, :user)
          .reject(&:excluded_from_trial_emails?)
          .reject(&:trial_finished_email_sent?)
      }

      scope :need_send_grace_period_email, -> do
        grace_period_ended = Store::DAYS_AFTER_TRIAL_ENDS_TO_NOTIFY_USER.days.ago.all_day
        where(trial_ends_at: grace_period_ended)
          .includes(:setting_objects, :user)
          .reject(&:excluded_from_trial_emails?)
          .reject(&:grace_period_email_sent?)
      end

      scope :need_send_miss_you_email, -> do
        date = Store::DAYS_AFTER_DEACTIVATION_TILL_MISS_YOU_EMAIL.days.ago
        where('trial_ends_at < ?', date)
          .includes(:setting_objects, :bundles, :user)
          .reject(&:miss_you_email_sent?)
          .reject {|s| !s.can_be_billed?}
          .reject(&:subscription?)
      end

      scope :need_send_deleted_email, -> do
        date = Store::DAYS_AFTER_DEACTIVATION_TILL_DELETED_EMAIL.days.ago
        where('deactivated_at < ?', date)
          .includes(:setting_objects, :bundles)
          .reject(&:store_deleted_email_sent?)
          .reject {|s| !s.can_be_billed?}
          .reject(&:subscription?)
      end

      # we send plan exceeding email only for stores with orders based billing
      scope :need_send_plan_exceeding_email, -> do
        with_orders_based_billing.plan_emails_not_suspended
          .joins(:store_subscription_usage)
          .includes(:setting_objects, bundles: :subscription)
          .merge(StoreSubscriptionUsage.exceeding_limit).find_each
          .select { |s| s.can_be_billed? && s.charge_extra_orders? }
          .reject(&:plan_exceeding_email_sent?)
      end

      def self.need_send_plan_exceeded_email
        orders_stores = with_orders_based_billing
                            .joins(:store_subscription_usage)
                            .includes(:setting_objects, bundles: :subscription)
                            .merge(StoreSubscriptionUsage.exceeded_limit)

        orders_stores = orders_stores.find_each.select { |s| s.can_be_billed? && s.subscription? && s.charge_extra_orders? }.reject(&:plan_exceeded_email_sent?)
        product_stores = with_products_based_billing.plan_emails_not_suspended
                             .joins(:store_products_usage, :store_subscription_usage, :bundles)
                             .where('store_products_usages.products_count > store_subscription_usages.max_products_limit')

        product_stores = product_stores.find_each.select { |s| s.can_be_billed? && s.subscription? }.reject(&:plan_exceeded_email_sent?)
        orders_stores.concat product_stores
      end
    end

    def plan_exceeding_email_sent?
      settings(:billing).plan_exceeding_email_sent
    end

    def plan_exceeded_email_sent?
      settings(:billing).plan_exceeded_email_sent
    end

    def trial_ending_email_sent?
      settings(:billing).trial_ending_email_sent
    end

    def trial_finished_email_sent?
      settings(:billing).trial_finished_email_sent
    end

    def grace_period_email_sent?
      settings(:billing).grace_period_email_sent
    end

    def miss_you_email_sent?
      settings(:billing).miss_you_email_sent
    end

    def store_deleted_email_sent?
      settings(:billing).store_deleted_email_sent
    end
  end
end

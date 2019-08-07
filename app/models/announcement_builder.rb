class AnnouncementBuilder
  attr_reader :v, :store

  BILLING_EMAIL = 'billing@helpfulcrowd.com'
  CHOOSE_PLAN_ACTION = 'Choose a plan'.freeze
  GO_BILLING_ACTION = 'Go to billing'.freeze
  GO_WIDGETS_CONSOLE_ACTION = 'Go to widgets console'.freeze

  CLEAN_UP_WIDGETS = "You could use widgets console to automatically remove our widgets from your store".freeze

  SUBSCRIPTION_EXPIRED = "Your subscription has been cancelled or expired. If you wish to continue using HelpfulCrowd,\
                          you need to choose and subscribe to a plan".freeze
  TRIAL_EXPIRING = "Your free trial is expiring soon. Choose and subscribe to a plan to avoid interruptions with using HelpfulCrowd".freeze
  TRIAL_EXPIRED = "Your free trial has expired. If you wish to continue using HelpfulCrowd, you need to choose and subscribe to a plan".freeze

  DUNNING_STARTED = "Unfortunately we were unable to process a payment. Please review and \
                    update payment details to avoid interruptions with using HelpfulCrowd".freeze
  DUNNING_FAILED = "Unfortunately several of our attempts to process payment have \
                    been unsuccessful. If you wish to continue using HelpfulCrowd,\
                    you need to review and update payment details".freeze

  SUBSCRIPTION_TERMINATING = "Your subscription will be cancelled at the end of current billing \
                              cycle. If you wish to continue using HelpfulCrowd, you need to \
                              renew your subscription".freeze
  PLAN_EXCEEDING_EXTENSIBLE = "You are close to exceeding your allowance of in-plan orders. Once you \
                               exceed the limit, you will be charged for out-of-plan orders".freeze
  PLAN_EXCEEDING_NOT_EXTENSIBLE = "Your are close to exceeding your allowance of in-plan orders. Once you \

                                  exceed the limit, you will need to upgrade to a higher plan".freeze
  PLAN_EXCEEDED_PRODUCTS = "Your store now has more products than your plan covers. Reviews for out-of-plan products are temporarily disabled. \
                            Upgrade to a higher plan to activate reviews for all your products".freeze
  PLAN_EXCEEDED_ORDERS_EXTENSIBLE = "You have exceeded your allowance of in-plan orders and you are now being \
                                    charged for out-of-plan orders. Consider upgrading to a higher value plan".freeze
  PLAN_EXCEEDED_ORDERS_NOT_EXTENSIBLE = "You have exceeded your allowance of in-plan orders. You need to upgrade to a higher plan".freeze

  SUBSCRIPTION_WITHHELD_PRODUCTS = "You store has more products than your plan covers. You need to upgrade to a higher plan".freeze
  SUBSCRIPTION_WITHHELD_ORDERS = "You have exceeded your allowance of in-plan orders. You need to upgrade to a higher plan".freeze

  RECONNECT_REQUIRED = "Looks like HelpfulCrowd lost access to your store. To ensure all \
                        our features work without interruption, please reconnect now".freeze

  EMAIL_ADMIN_RESTRICTION = "Emails to customers are currently not being sent to customers. Please contact support for assistance.".freeze
  EMAIL_USER_RESTRICTION = "No emails are currently being sent to customers.".freeze
  REVIEW_EMAIL_EDITOR_UPDATED = "We've updated the reviews email templates editor. Please CHECK and UPDATE your email format before sending any more emails.".freeze
  QUESTION_EMAIL_EDITOR_UPDATED = "We've updated the Q&A email templates editor. Please CHECK and UPDATE your email format before sending any more emails.".freeze
  PROMOTION_EDITOR_UPDATED = "We've updated the promotions templates editor. Please CHECK and UPDATE your email format before sending any more emails.".freeze

  Action = Struct.new(:url, :label, :blank) do
    def target
      return nil unless blank?
      '_blank'
    end
  end

  Announcement = Struct.new(:message, :type, :action, :hide_action) do
    def action?
      action.present?
    end
  end

  def initialize(store, view_context = ActionView::Base)
    @v     = view_context
    @store = store
  end

  def announcements
    [problems_with_store_announcement, billing_announcement, email_templates_announcements, email_restriction_announcement].flatten.compact
  end

  def problems_with_store_announcement
    announcements = []
    announcements << reconnect_required if store.present? && !store.installed?
    announcements
  end

  def clean_up_widgets
    action = Action.new v.widget_console_back_tools_url, GO_WIDGETS_CONSOLE_ACTION
    Announcement.new CLEAN_UP_WIDGETS, 'warning', action
  end

  def billing_announcement
    return nil if store.nil? || !store.can_be_billed?

    return dunning_failed           if store.dunning_failed?
    return dunning_started          if store.dunning?
    return trial_expired            if store.never_paid? && store.trial_ended?
    return trial_expiring           if store.trial_ending?
    return subscription_terminating if store.terminating?
    return subscription_expired     if store.cancelled?
    return plan_exceeding           if store.plan_exceeding?
    return plan_exceeded            if store.plan_exceeded?
    return subscription_withheld    if store.withheld?
    nil
  end

  def email_restriction_announcement
    return unless store.present?

    return email_admin_restriction if store.settings(:admin_only).restrict_outgoing_emails.to_b
    email_user_restriction  if store.settings(:global).restrict_outgoing_emails.to_b
  end

  def email_templates_announcements
    templates_updated = []

    templates_updated << reviews_templates_updated if store.settings(:reviews).check_required.to_b
    templates_updated << questions_templates_updated if store.settings(:questions).check_required.to_b
    templates_updated << promotions_templates_updated if @store.promotions.any? && store.settings(:promotions).check_required.to_b

    templates_updated
  end

  def build_announcement(message, level, action_message = nil)
    action = Action.new v.billing_back_settings_url, action_message
    Announcement.new message, level, action
  end

  def subscription_expired
    build_announcement SUBSCRIPTION_EXPIRED, 'danger', CHOOSE_PLAN_ACTION
  end

  def trial_expiring
    build_announcement TRIAL_EXPIRING, 'warning', CHOOSE_PLAN_ACTION
  end

  def trial_expired
    build_announcement TRIAL_EXPIRED, 'danger', CHOOSE_PLAN_ACTION
  end

  def dunning_started
    build_announcement DUNNING_STARTED, 'warning', GO_BILLING_ACTION
  end

  def dunning_failed
    build_announcement DUNNING_FAILED, 'danger', GO_BILLING_ACTION
  end

  def subscription_terminating
    build_announcement SUBSCRIPTION_TERMINATING, 'warning', GO_BILLING_ACTION
  end

  def plan_exceeding
    message = store.active_subscription.plan_extensible? ? PLAN_EXCEEDING_EXTENSIBLE : PLAN_EXCEEDING_NOT_EXTENSIBLE
    build_announcement message, 'warning', 'View plan usage'
  end

  def plan_exceeded
    message = if store.products_based_billing?
                PLAN_EXCEEDED_PRODUCTS
              else
                store.active_subscription.plan_extensible? ? PLAN_EXCEEDED_ORDERS_EXTENSIBLE : PLAN_EXCEEDED_ORDERS_NOT_EXTENSIBLE
              end
    build_announcement message, 'danger', 'Upgrade'
  end

  def subscription_withheld
    message = store.products_based_billing? ? SUBSCRIPTION_WITHHELD_PRODUCTS : SUBSCRIPTION_WITHHELD_ORDERS

    build_announcement message, 'danger'
  end

  def reconnect_required
    action  = Action.new v.connect_store_path(store), 'Reconnect store'
    Announcement.new RECONNECT_REQUIRED, 'warning', action
  end

  def email_admin_restriction
    Announcement.new EMAIL_ADMIN_RESTRICTION, 'warning', nil
  end

  def email_user_restriction
    action  = Action.new v.general_back_settings_path(anchor: "app-status"), 'Change under App status'
    Announcement.new EMAIL_USER_RESTRICTION, 'warning', action
  end

  def reviews_templates_updated
    action  = Action.new v.emails_back_reviews_path, 'Check'
    hide_action = Action.new v.hide_reviews_check_announcement_back_reviews_path, 'Hide'
    Announcement.new REVIEW_EMAIL_EDITOR_UPDATED, 'success', action, hide_action
  end

  def questions_templates_updated
    action  = Action.new v.emails_back_questions_path(anchor: "question_reply_notification"), 'Check'
    hide_action = Action.new v.hide_questions_check_announcement_back_questions_path, 'Hide'
    Announcement.new QUESTION_EMAIL_EDITOR_UPDATED, 'success', action, hide_action
  end

  def promotions_templates_updated
    action  = Action.new v.back_promotions_path, 'Check'
    hide_action = Action.new v.back_hide_promotions_check_announcement_path, 'Hide'
    Announcement.new PROMOTION_EDITOR_UPDATED, 'success', action, hide_action
  end
end

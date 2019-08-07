class BackMailer < ApplicationMailer
  default from: "HelpfulCrowd <#{ENV['MAILER_DEFAULT_FROM']}>"
  layout 'mailer/back'

  FROM_SCOTT   = "Scott Stewart <scott@helpfulcrowd.com>".freeze
  FROM_BILLING = "HelpfulCrowd Billing <billing@helpfulcrowd.com>".freeze
  FROM_SUPPORT = "HelpfulCrowd Support <support@helpfulcrowd.com>".freeze

  def pending(review)
    smtp_api_headers ["To store owner", "Pending", "Review"]

    @review = review

    mail(to: review.user_email, subject: "New review for #{review.product_name}")
  end

  def flagged_review(review)
    smtp_api_headers ["To store owner", "Flagged", "Review"]

    @review = review

    mail(to: review.user_email, subject: "Review for #{review.product_name} was flagged")
  end

  def explicit_media(review)
    smtp_api_headers ["To store owner", "Explicit media", "Review"]

    @review = review

    mail(to: review.user_email, subject: "Review may contain explicit media")
  end

  def inappropriate_content(abuse_report)
    content_type = abuse_report.inappropriate_content_type

    smtp_api_headers ["To store owner", "Inappropriate content", content_type]

    @abuse_report = abuse_report

    mail(to: abuse_report.user.email, subject: "#{content_type} was marked as inappropriate")
  end

  def pending_question(question)
    smtp_api_headers ["To store owner", "Pending", "Q&A"]

    @question = question

    mail(to: question.store.user.email, subject: "New question for #{question.product.name}")
  end

  def flagged_question(question)
    smtp_api_headers ["To store owner", "Flagged", "Q&A"]

    @question = question

    mail(to: question.store.user.email, subject: "Question for #{question.product.name} was flagged")
  end

  def unimported_questions(user_id, imported_count, unimported_count)
    smtp_api_headers ["To store owner", "Import", "Q&As", "Unimported rows"]

    @user             = User.find(user_id)
    @imported_count   = imported_count
    @unimported_count = unimported_count

    mail(to: @user.email, subject: 'Your attention required to complete importing questions into HelpfulCrowd')
  end

  def unimported_reviews(user_id, imported_count, unimported_count)

    smtp_api_headers ["To store owner", "Import", "Reviews", "Unimported rows"]

    @user                  = User.find user_id
    @imported_count        = imported_count
    @unimported_count      = unimported_count

    mail(to: @user.email, subject: 'Your attention required to complete importing reviews into HelpfulCrowd')
  end

  def unimported_review_requests(user_id, imported_count, unimported_count)
    smtp_api_headers ["To store owner", "Import", "Requests", "Unimported rows"]

    @user                  = User.find user_id
    @imported_count        = imported_count
    @unimported_count      = unimported_count

    mail(to: @user.email, subject: 'Your attention required to complete importing review requests into HelpfulCrowd')
  end

  def unimported_products(user_id, imported_count, unimported_count)
    smtp_api_headers ["To store owner", "Import", "Products", "Unimported rows"]

    @user                  = User.find(user_id)
    @imported_count        = imported_count
    @unimported_count      = unimported_count

    mail(to: @user.email, subject: 'Your attention required to complete importing products into HelpfulCrowd')
  end

  def incorrect_format_of_reviews_csv(user_id)
    smtp_api_headers ["To store owner", "Import", "Reviews", "Incorrect Format"]

    @user = User.find(user_id)

    mail(to: @user.email, subject: 'Your attention required to complete importing reviews into HelpfulCrowd')
  end

  def subscription_changed(store_id)
    smtp_api_headers ['To store owner', 'Billing', 'Subscription changed']

    store = Store.find store_id
    @presenter = Emails::SubscriptionChangedPresenter.new(store)

    subject         = "Your HelpfulCrowd subscription has been updated"
    mail(to: @presenter.user_email, subject: subject, from: FROM_BILLING)
  end

  def plan_exceeded(store_id)
    smtp_api_headers ['To store owner', 'Billing', 'Plan exceeded']

    store            = Store.find store_id
    @presenter = Emails::PlanExceededPresenter.new(store)
    @user            = store.user
    @plan_extensible = store.active_subscription.plan_extensible?
    subject          = "You have exceeded your monthly plan allowance on HelpfulCrowd"

    mail(to: @user.email, subject: subject, from: FROM_BILLING)
  end

  def plan_exceeding(store_id)
    smtp_api_headers ['To store owner', 'Billing', 'Plan exceeding']

    store            = Store.find(store_id)
    @user            = store.user
    @plan_extensible = store.active_subscription.plan_extensible?
    subject          = "You are close to exceeding your monthly plan allowance on HelpfulCrowd"

    mail(to: @user.email, subject: subject, from: FROM_BILLING)
  end

  def free_plan_withheld(store_id)
    smtp_api_headers ['To store owner', 'Billing', 'Free plan withheld']

    store   = Store.find(store_id)
    @user   = store.user
    subject = "Your must upgrade to a paid HelpfulCrowd subscription"

    mail(to: @user.email, subject: subject, from: FROM_BILLING)
  end

  def trial_ending(store_id)
    smtp_api_headers ['To store owner', 'Billing', 'Trial ending']

    store      = Store.find store_id
    @presenter = StoreTrialPresenter.new store, view_context

    subject = "Only 2 days left in Your HelpfulCrowd trial"
    mail(to: @presenter.user_email, subject: subject, from: FROM_BILLING)
  end

  def trial_finished(store_id)
    smtp_api_headers ['To store owner', 'Billing', 'Trial ended']

    store      = Store.find store_id
    @presenter = StoreTrialPresenter.new store, view_context

    subject = "Your HelpfulCrowd trial has ended"
    mail(to: @presenter.user_email, subject: subject, from: FROM_BILLING)
  end

  def grace_period_ended(store_id)
    smtp_api_headers ['To store owner', 'Billing', 'Grace period ended']

    store      = Store.find store_id
    @presenter = StoreTrialPresenter.new store, view_context

    subject = "Important: Your HelpfulCrowd account will be deactivated soon"
    mail(to: @presenter.user_email, subject: subject, from: FROM_BILLING)
  end

  def miss_you(store_id)
    smtp_api_headers ['To store owner', 'Billing', 'Account suspended']

    store      = Store.find store_id
    @presenter = StoreTrialPresenter.new store, view_context

    subject = "Important: Your HelpfulCrowd account has been suspended"
    mail(to: @presenter.user_email, subject: subject, from: FROM_BILLING)
  end

  def store_deleted(store_id)
    smtp_api_headers ['To store owner', 'Billing', 'Account deactivated']

    store      = Store.find store_id
    @presenter = StoreTrialPresenter.new store, view_context

    subject = "Important: Your HelpfulCrowd account has been deactivated"
    mail(to: @presenter.user_email, subject: subject, from: FROM_SUPPORT)
  end

  # Authentication-related custom emails
  def require_oauth_instead_of_email_auth(store_id)
    # smtp_api_headers ['To store owner', 'Authentication', 'Require OAuth'] TODO we are not tagging any devise emails yet. We need to

    @store  = Store.find store_id
    @user   = @store.user
    subject = "Signing in to HelpfulCrowd: please use an alternative method"
    mail(to: @user.email, subject: subject)
  end

  # GDPR-related emails
  def data_access_request(store_id, customer_email)
    smtp_api_headers ["To store owner", "GDPR", "Customer", "Data access request"]
    @store    = Store.find(store_id)
    @customer = store.customers.find_by_email(customer_email)
    @user     = customer.store.user

    mail(to: @user.email, subject: "Data access request from customer")
  end

  # Downloads related emails
  def reviews_export_ready(store_id)
    smtp_api_headers ["To store owner", "Downloads", "Reviews export"]
    @store    = Store.find(store_id)
    @user     = @store.user

    mail(to: @user.email, subject: "Reviews export ready for download")
  end

  def questions_export_ready(store_id)
    smtp_api_headers ["To store owner", "Downloads", "Questions export"]
    @store    = Store.find(store_id)
    @user     = @store.user

    mail(to: @user.email, subject: "Questions export ready for download")
  end

  private

  def smtp_api_headers(categories)
    headers "X-SMTPAPI" => { category: categories }.to_json
  end
end

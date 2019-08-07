class Admin::DashboardsController < AdminController

  before_action :set_media,           only: [         :feature_usage ]
  before_action :set_product_groups,  only: [ :index, :feature_usage ]
  before_action :set_products,        only: [ :index, :feature_usage ]
  before_action :set_questions,       only: [ :index, :feature_usage ]
  before_action :set_review_requests, only: [ :index, :feature_usage ]
  before_action :set_reviews,         only: [ :index, :feature_usage ]
  before_action :set_stores,          only: [ :index, :feature_usage ]
  before_action :set_social_posts,    only: [ :index, :feature_usage ]
  before_action :set_users,           only: [ :index, :feature_usage ]
  before_action :set_votes,           only: [         :feature_usage ]
  before_action :set_flags,           only: [         :feature_usage ]
  before_action :set_abuse_reports,   only: [         :feature_usage ]
  before_action :set_order_values,    only: [ :index ]

  def index
  end

  def authentication_stats
    @sign_ins = Ahoy::Event.where(name: 'sign in').joins(:user).where(users: { role: 'standard' }).all
    @sign_ups = Ahoy::Event.where(name: 'sign up').joins(:user).where(users: { role: 'standard' }).all
    @connects = Ahoy::Event.where(name: 'connect').joins(:user).where(users: { role: 'standard' }).all
  end

  def billing
    @subscriptions = Subscription.where(state: [:active, :non_renewing])
                                 .joins(:bundle)
                                 .includes(:initial_bundle, { bundle:  [:plans, { store: :store_subscription_usage }] })
                                 .order('next_billing_at ASC')
                                 .paginate(page: params[:page], per_page: 20)
    @presenters = @subscriptions.map { |s| Admin::SubscriptionChargesPresenter.new s, view_context }
  end

  def reporting
  end

  def problematic_stores
    @stores = Store.have_sync_error.includes(:ecommerce_platform)
  end

  protected

  def set_media
    @media = Medium.all
  end

  def set_product_groups
    @product_groups = ProductGroup.all
  end

  def set_products
    @products = Product.all
  end

  def set_questions
    @questions = Question.all
  end

  def set_review_requests
    @review_requests = ReviewRequest.all
  end

  def set_reviews
    @reviews = Review.all
  end

  def set_stores
    @stores = Store.all
  end

  def set_social_posts
    @social_posts = SocialPost.all
  end

  def set_users
    @users = User.all
  end

  def set_votes
    @votes = Vote.all
  end

  def set_flags
    @flags = Flag.all
  end

  def set_abuse_reports
    @abuse_reports = AbuseReport.all
  end

  # Get today's orders total by provider
  def set_order_values
    @providers = Hash.new({})

    return # skip orders chart setting for now

    [*(Date.current - 30.day)..Date.current].each do |date|
      EcommercePlatform::SUPPORTED_PLATFORMS.each do |platform|
        @providers[platform][date.to_s] = 0
      end
    end

    Rails.cache.fetch ['admin/orders-value-per-day', Date.today] do
      orders = Order.joins(customer: [store: :ecommerce_platform]).
             select("total, currency, ecommerce_platforms.name as provider, orders.created_at as created_at").
             where(orders: { created_at: (Time.current - 30.days).beginning_of_day..Time.current.end_of_day })

      orders.each do |order|
        @providers[order.provider][order.created_at.to_date.to_s] += HcMoney.new(order.total, currency: order.currency).as_usd.to_f
      end
    end
  end
end

class Front::SuppressionsController < FrontController

  before_action :set_customer, only: [:manage_subscriptions, :index, :show, :create, :destroy]

  def manage_subscriptions
    @uid = params[:uid]

    if params[:unsubscribe] == 'true'
      @customer.suppress(:by_customer)

      email = Email.find_by_helpful_id(@uid) if @uid.present?

      EmailEvent.create(email: email, event: 'Unsubscribe', timestamp: DateTime.current, source: :hc) if email.present?

      @change = true
    end

    @unsubscribed = @customer.suppressed?(:by_customer)
    @suppression  = @unsubscribed ? @customer.suppressions(:by_customer).first : Suppression.new
  end

  def index
    redirect_to manage_subscriptions_front_suppressions_url(@store.hashid, customer_id: @customer.hashid, uid: params[:uid])
  end

  def show
    redirect_to manage_subscriptions_front_suppressions_url(@store.hashid, customer_id: @customer.hashid, uid: params[:uid])
  end

  def create
    @suppression = Suppression.new(customer: @customer, email: @customer.email, store: @store, source: :by_customer)

    if @suppression.save
      @uid  = params[:uid]
      email = Email.find_by_helpful_id(@uid) if @uid.present?

      EmailEvent.create(email: email, event: 'Unsubscribe', timestamp: DateTime.current, source: :hc) if email.present?

      @change       = true
      @unsubscribed = true

      render 'manage_subscriptions'
    end
  end

  def destroy
    @suppression = @store.suppressions.find_by_hashid(params[:id])

    if @suppression.destroy
      @uid          = params[:uid]
      @change       = true
      @unsubscribed = false

      render 'manage_subscriptions'
    end
  end

  private

  def set_customer
    @customer = @store.customers.find_by_hashid(params[:customer_id])
  end

end

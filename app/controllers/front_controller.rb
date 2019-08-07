class FrontController < ApplicationController
  layout 'front'

  ## Callbacks
  before_action     :set_store
  before_action     :check_store
  before_action     :set_customer
  before_action     :set_locale
  before_action     :set_time_zone

  after_action      :embedded_storefront
  skip_after_action :intercom_rails_auto_include

  protect_from_forgery with: :null_session, if: Proc.new { |c| c.request.format == 'application/json' }

  helper_method :storefront_reviews?

  protected

  def storefront_reviews?
    authenticated_as_guest = @guest_customer&.valid?
    @store&.accepts_storefront_reviews? authenticated_as_guest
  end

  def embedded_storefront
    response.headers['Access-Control-Allow-Origin']      = request.headers['origin']
    response.headers['Access-Control-Allow-Credentials'] = true
    response.headers['Access-Control-Allow-Methods']     = 'POST, PUT, DELETE, GET, OPTIONS, PATCH'
  end

  def set_store
    @store = Store.find_by_id_from_provider_or_hashid(params[:store_id])
  end

  def check_store
    if @store.present? && @store.user.present?
      if @store.user.deleted?
        not_found unless @store.settings(:global).keep_hc_active.to_b
      end
    end
  end

  def set_locale
    if request.headers['HTTP_HC_LOCALE'].present?
      requested_locale = request.headers['HTTP_HC_LOCALE'].delete('"').to_sym
    end

    I18n.locale = FrontLanguage.supports?(requested_locale) ? requested_locale : @store.locale
  end

  def set_time_zone
    Time.zone = @store.time_zone if @store.present?
  end

  def set_customer
    customer_header = request.headers['HTTP_HC_GUEST_CUSTOMER']
    return unless customer_header.present?

    @guest_customer = GuestCustomer.from_customer_header customer_header
    @current_customer = @store.customers.find_by email: @guest_customer.email
  rescue JSON::ParserError => _
    return false
  end
end

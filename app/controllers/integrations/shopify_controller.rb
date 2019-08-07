class Integrations::ShopifyController < ApplicationController

  class ShopifyDomainNotFound < StandardError; end

  layout 'integrations/shopify/back'

  before_action     :authenticate_from_shopify,
                    :set_store

  rescue_from ActiveResource::UnauthorizedAccess, with: :close_session

  protected

  def close_session
    sign_out(current_user) if current_user
    redirect_to shopify_login_url
  end

  def set_store
    @store = current_user.store
  end

  def fullpage_redirect_to(url)
    render 'redirect', locals: { url: url, current_shopify_domain: shopify_domain}
  end

  def authenticate_from_shopify
    return if current_user.present?
    if params[:hmac].blank?
      redirect_to_shopify_oauth
      return
    end
    return head :unauthorized unless validate_hmac
    store = Store.shopify.find_by_domain(@shopify_store_domain)
    if store.present? && store.installed?
      sign_in(store.user)
      ahoy.authenticate(store.user)
      ahoy.track 'sign in', user_id: store.user.id, referrer: 'from Shopify'
    else
      redirect_to_shopify_oauth
    end
  end

  def validate_hmac
    return false if params[:hmac].blank?
    permitted_params = params.permit(:shop, :timestamp, :locale, :protocol)
    digest = hmac_digest permitted_params
    ActiveSupport::SecurityUtils.secure_compare(digest, params[:hmac])
  end

  def hmac_digest(options)
    sha256 = OpenSSL::Digest::SHA256.new
    client_secret = ENV['SHOPIFY_SHARED_SECRET']
    message = URI.unescape(options.to_query)
    OpenSSL::HMAC.hexdigest(sha256, client_secret, message)
  end

  def shopify_domain
    return @shopify_store_domain if @shopify_store_domain.present?
    raise ShopifyDomainNotFound
  end
end

class Callbacks::ShopifyController < CallbacksController
  before_action :verify_request, :parse_data

  def create
    ShopifyWebhookWorker.perform_async @store.id, @data, params.permit(params.keys).to_h
    head(:ok)
  end

  private
  def verify_request
    if shopify_hmac.blank?
      head(:ok) && return
    end

    unless is_redact
      return head(:unauthorized) unless hmac_valid?(request.raw_post)
    end
  end

  def is_redact
    (params[:object] == 'shop' && params[:event] == 'redact') || (params[:object] == 'customers' && %w(redact data_request).include?(params[:event]))
  end

  def hmac_valid?(data)
    digest = OpenSSL::Digest.new('sha256')
    shopify_digest = Base64.encode64(OpenSSL::HMAC.digest(digest, shopify_shared_secret, data)).strip
    ActiveSupport::SecurityUtils.secure_compare(shopify_hmac, shopify_digest)
  end

  def shopify_shared_secret
    ENV['SHOPIFY_SHARED_SECRET']
  end

  def shop_domain
    request.headers['HTTP_X_SHOPIFY_SHOP_DOMAIN']
  end

  def shopify_hmac
    request.headers['HTTP_X_SHOPIFY_HMAC_SHA256']
  end

  def parse_data
    if is_redact
      head(:ok)
    else
      @store = Store.shopify.find_by domain: shop_domain
      if @store.present? #TODO #456
        if request.headers['Content-Type'] == 'application/json'
          @data = JSON.parse(request.body.read)
        else
          @data = params.as_json
        end
      else
        head(:ok)
      end
    end
  end
end

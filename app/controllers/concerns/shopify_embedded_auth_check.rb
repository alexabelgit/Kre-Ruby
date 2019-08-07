module ShopifyEmbeddedAuthCheck
  extend ActiveSupport::Concern

  included do
    before_action :check_shopify_embedded_auth

    protected

    def check_shopify_embedded_auth
      current_controller = request.filtered_parameters['controller']
      if current_controller.include?('integrations/shopify')
        response.set_header('P3P', 'CP="Not used"')
        response.headers['X-Frame-Options'] = shopify_x_frame_options
      end
      @shopify_store_domain = nil
      unless current_controller.include?('oauth/shopify_sessions') || current_controller.include?('oauth/callbacks')
        @shopify_store_domain = params[:shop]
      end
      @shopify_store_domain ||= params[:shopify_store_domain] || request.headers['HTTP_X_SHOPIFY_DOMAIN'] || current_user&.store&.domain
      shopify_login_again_if_different_shop
    end

    def shopify_x_frame_options
      return 'ALLOWALL' unless @shopify_store_domain
      "ALLOW-FROM https://#{@shopify_store_domain}/"
    end

    def redirect_to_shopify_oauth
      if request.xhr?
        head :unauthorized
      else
        redirect_to shopify_login_url
      end
    end

    def shopify_login_url
      url = new_oauth_shopify_session_url
      if @shopify_store_domain.present?
        query = { shop: @shopify_store_domain, iframe: true }.to_query
        url = "#{url}?#{query}"
      end
      url
    end

    def shopify_login_again_if_different_shop
      if shopify_should_login_again?
        sign_out(current_user)
        redirect_to_shopify_oauth
      end
    end

    def shopify_should_login_again?
      current_user.present? &&
        @shopify_store_domain.present? &&
        @shopify_store_domain.is_a?(String) &&
        (!current_user.installed? || current_user.store.domain != @shopify_store_domain)
    end
  end
end

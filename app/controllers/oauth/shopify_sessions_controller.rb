module Oauth
  class ShopifySessionsController < OauthController

    SHOPIFY_OAUTH_URL     = "/auth/shopify"
    SHOPIFY_DOMAIN_REGEXP = /(?:https?:\/\/)?(?<domain>(?<store_handle>.+)\.myshopify.com)/

    def new
      store_handle = params[:shop]
      if store_handle.blank?
        flash[:danger] = "Please fill in store address to continue"

        if Rails.application.routes.recognize_path(request.referrer)[:controller] == 'users/registrations'
          redirect_to sign_up_with_shopify_url
        elsif Rails.application.routes.recognize_path(request.referrer)[:controller] == 'back/stores'
          redirect_to connect_with_shopify_back_stores_url
        else
          redirect_to sign_in_with_shopify_url
        end
      else
        redirect_to shopify_oauth_url(shopify_url(store_handle))
      end
    end

    def success
      if Rails.env.test?
        pass_by_oauth_initialization_in_test_env && return
      end

      store_domain = auth_hash[:uid]
      token        = auth_hash.dig(:credentials, :token)
      service      = ShopifyInitializationService.new(current_user, token, store_domain)
      result       = service.call initiated_from_shopify?

      if result.success?
        handle_initialization_success result
      else
        handle_initialization_error result
      end
    end

    private

    def pass_by_oauth_initialization_in_test_env
      store = Store.find_by id_from_provider: auth_hash[:uid]
      result = Result.new entity: store, success: true, status: :landing_sign_in
      handle_initialization_success result
    end

    def handle_initialization_success(result)
      store = result.entity
      sign_in store.user

      track_authentication(store.user, result)

      store_handle = Shopify::UrlSanitizer.extract_shop_handle store.domain
      cookies[:shopify_store_handle] = store_handle if store_handle

      case result.status
      when :landing_sign_up, :app_sign_up
        flash[:success] = I18n.t("oauth.shopify.landing.connected.html", store_name: store.name)
        redirect_to onboarding_back_tools_path
      when :landing_sign_in, :app_sign_in
        flash[:info]    = I18n.t("devise.sessions.signed_in"), :fade
        redirect_to back_dashboard_index_path
      when :tab_sign_in
        redirect_to back_dashboard_index_url
      when :tab_sign_up
        redirect_to onboarding_back_tools_url
      else
        # shouldn't happen normally since we cover all possible results
        # if successful oauth got here then somewhere we messed with result status
        redirect_to root_path
      end
    end

    def handle_initialization_error(result)
      flash[:error] = result.error_message
      case result.status
      when :store_already_connected
        redirect_to connect_back_stores_path
      else
        redirect_to new_user_session_path
      end
    end

    def track_authentication(user, result)
      action = result.status.to_s.humanize.downcase
      referrer = initiated_from_shopify? ? 'from Shopify' : 'with Shopify'
      AhoyTracker.new(ahoy, user).authenticate.track(action, referrer)
    end

    def shopify_store_handle(url)
      regex_match = url.match(SHOPIFY_DOMAIN_REGEXP)
      regex_match.present? ? regex_match[:store_handle] : false
    end

    def shopify_url(store_handle)
      store_handle.slice!('.myshopify.com')
      "#{store_handle}.myshopify.com"
    end

    def auth_hash
      request.env['omniauth.auth'] || {}
    end

    def initiated_from_shopify?
      !request.env['omniauth.params'].fetch('from_hc', false).to_b
    end

    def shopify_oauth_url(domain)
      from_hc = !params[:iframe].to_b
      "#{SHOPIFY_OAUTH_URL}?shop=#{domain}&from_hc=#{from_hc}"
    end
    
  end
end

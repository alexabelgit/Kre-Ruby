module Oauth
  class EcwidSessionsController < OauthController

    def new
      session[:omniauth_return_to] = request.referer
      redirect_to "/auth/ecwid?from_hc=true"
    end

    def success
      ecwid_token = auth_hash.credentials.token
      store_id = auth_hash.uid

      service = EcwidInitializationService.new(ecwid_token, store_id, current_user)
      result = service.call initiated_from_ecwid?

      if result.success?
        handle_initialization_success result
      else
        handle_initialization_error result
      end
    end

    private

    def handle_initialization_success(result)
      store = result.entity
      case result.status
      when :landing_sign_up
        flash[:success] = I18n.t("oauth.ecwid.landing.connected.html",
                                 store_name: store.name)
        authenticate_and_track store, 'with Ecwid', 'sign up'
        redirect_to onboarding_back_tools_path
      when :landing_sign_in
        flash[:info] = I18n.t("devise.sessions.signed_in"), :fade
        authenticate_and_track store, 'with Ecwid', 'sign in'
        redirect_to back_dashboard_index_path
      when :app_sign_in, :app_sign_up
        flash[:success] = I18n.t("oauth.ecwid.landing.connected.html",
                                 store_name: store.name)
        authenticate_and_track store, 'with Ecwid', 'connect'
        redirect_to onboarding_back_tools_path
      when :tab_sign_in
        authenticate_and_track store, 'from Ecwid', 'sign in'
        response.headers['X-Frame-Options'] = 'ALLOWALL'
        redirect_to integrations_ecwid_dashboard_index_url
      when :tab_sign_up
        flash[:success] = I18n.t("oauth.ecwid.iframe.connected.html",
                                 store_name: store.name,
                                 url:        onboarding_back_tools_url)
        response.headers['X-Frame-Options'] = 'ALLOWALL'
        authenticate_and_track store, 'from Ecwid', 'sign up'
        redirect_to integrations_ecwid_dashboard_index_url
      else
        # shouldn't happen normally since we cover all possible results
        # if successful oauth got here then somewhere we messed with result status
        redirect_to root_path
      end
    end

    def handle_initialization_error(result)
      flash[:error] = result.error_message

      case result.status
      when :landing_account_exists, :not_available_on_current_plan
        redirect_to new_user_session_path
      when :tab_account_exists
        response.headers['X-Frame-Options'] = 'ALLOWALL'
        render template: 'integrations/ecwid/shared/error', layout: 'integrations/ecwid/back'
      when :store_already_connected
        redirect_to connect_back_stores_path
      else
        redirect_to new_user_session_path
      end
    end

    def authenticate_and_track(store, referrer, action)
      user = store.user
      sign_in user
      AhoyTracker.new(ahoy, store.user).authenticate.track(action, referrer)
    end

    def auth_hash
      request.env['omniauth.auth'] || {}
    end

    def initiated_from_ecwid?
      init_from_hc = request.env['omniauth.params'].fetch('from_hc', false).to_b
      !init_from_hc
    end
  end
end

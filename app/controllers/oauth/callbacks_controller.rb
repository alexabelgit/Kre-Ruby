module Oauth
  class CallbacksController < OauthController

    SOCIAL_NETWORK_PROVIDERS = [:facebook, :twitter, :instagram, :pinterest].freeze
    ECOMMERCE_PROVIDERS      = [:shopify, :ecwid]

    def success
      case
      when social_network_callback?
        process_social_network_callback
      when ecommerce_callback?
        process_ecommerce_callback
      else
        unknown_oauth_provider
      end
    end

    def failure
      oauth_error   = params[:message]
      provider      = params[:strategy]
      flash[:error] = I18n.t("oauth.errors.#{oauth_error}", default: 'Authentication attempt failed. Please try again or contact us if the problem persists')

      redirect_to back_url(oauth_error, provider)
    end

    protected

    # manually constructs :back url here so we can add anchor
    def back_url(oauth_error, provider)
      base_url = oauth_origin || request.referer || root_path
      "#{base_url}?error=#{oauth_error}##{provider}"
    end

    def process_social_network_callback
      current_user.from_omniauth(auth_hash) if current_user.present?

      case provider
      when :facebook
        flash[:info] = I18n.t("oauth.flash.facebook.select_page")
        redirect_to social_accounts_back_settings_url(anchor: provider)
      when :twitter
        flash[:success] = I18n.t("oauth.flash.twitter.success")
        redirect_to social_accounts_back_settings_url
      else
        unkown_oauth_provider
      end
    end

    def process_ecommerce_callback
      case provider
      when :shopify
        ShopifySessionsController.dispatch("success", request, response)
      when :ecwid
        EcwidSessionsController.dispatch("success", request, response)
      else
        unkown_oauth_provider
      end
    end

    def unknown_oauth_provider
      flash[:danger] = I18n.t("oauth.errors.unknown_provider")
      redirect_to root_path
    end

    def social_network_callback?
      SOCIAL_NETWORK_PROVIDERS.include? provider
    end

    def ecommerce_callback?
      ECOMMERCE_PROVIDERS.include? provider
    end

    def provider
      auth_hash[:provider].to_sym
    end

    def oauth_error
      auth
    end

    def oauth_origin
      session.delete(:omniauth_return_to)
    end

    def auth_hash
      request.env['omniauth.auth'] || {}
    end
  end
end

require 'omniauth/strategies/oauth2'

module OmniAuth
  module Strategies
    class Ecwid < OmniAuth::Strategies::OAuth2

      option :name, "ecwid"
      option :client_options, {
               :site => 'https://my.ecwid.com',
               :authorize_url => '/api/oauth/authorize',
               :token_url => '/api/oauth/token'
             }

      option :authorize_options, [:scope]
      option :callback_url

      uid {
        access_token.params.fetch("store_id")
      }

      info {
        if access_token
          email = access_token.params.fetch('email')
          { name: email, email: email }
        end
      }

      extra {
        if access_token
          {
            store_id: access_token.params.fetch('store_id'),
            public_token: access_token.params.fetch('public_token')
          }
        end
      }

      def callback_url
        options[:callback_url] || full_host + script_name + callback_path
      end
    end
  end
end

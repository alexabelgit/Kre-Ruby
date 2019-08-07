module OmniAuth
  module Strategies
    autoload 'Ecwid', Rails.root.join('app', 'lib', 'omniauth', 'strategies', 'ecwid')
  end
end

OmniAuth.config.failure_raise_out_environments = ['test']

Koala.config.api_version = "v2.12"

Rails.application.config.middleware.use OmniAuth::Builder do

  provider :facebook,
           ENV['FACEBOOK_APP_ID'],
           ENV['FACEBOOK_APP_SECRET'],
           { info_fields: 'email,first_name,last_name',
             scope:       'manage_pages, publish_pages' }

  provider :twitter,
           ENV['TWITTER_API_KEY'],
           ENV['TWITTER_API_SECRET']

  provider :shopify,
           ENV['SHOPIFY_API_KEY'],
           ENV['SHOPIFY_SHARED_SECRET'],
           scope: ENV['SHOPIFY_SCOPE']

  provider :ecwid,
           ENV['ECWID_CLIENT_ID'],
           ENV['ECWID_CLIENT_SECRET'],
           scope: ENV['ECWID_SCOPE']
end

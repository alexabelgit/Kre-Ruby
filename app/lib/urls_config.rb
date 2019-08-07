class UrlsConfig
  def self.init(configuration)
    configuration.urls_config = ActiveSupport::OrderedOptions.new
    config = configuration.urls_config

    default_app_host = Rails.env.development? ? 'localhost' : 'app.helpfulcrowd.com'
    default_app_port = Rails.env.development? ? 3000 : 80

    config.app_protocol = ENV.fetch('WEB_APP_PROTOCOL', 'http')
    config.app_host = ENV.fetch('WEB_APP_HOST', default_app_host)

    if Rails.env.production?
      heroku_review_app_name = ENV['HEROKU_APP_NAME']
      use_heroku_name = heroku_review_app_name && heroku_review_app_name != 'helpfulcrowd-production'
      config.app_host = "#{heroku_review_app_name}.herokuapp.com" if use_heroku_name

      config.url_options = {
          trailing_slash: true,
          protocol:       config.app_protocol,
          host:           config.app_host
      }

      config.app_url = "#{config.app_protocol}://#{config.app_host}"

      if use_heroku_name
        config.asset_host = config.app_url
      else
        config.asset_host = ENV.fetch('ASSET_HOST')
      end
    else
      ngrok_on = ENV.fetch('NGROK_ON', false)
      ngrok_host = ENV.fetch('NGROK_HOST', '')

      config.app_port = ENV.fetch('WEB_APP_PORT', default_app_port)
      config.app_port = nil if ngrok_on.to_b || config.app_protocol == 'https'

      config.app_host = ngrok_on.to_b ? ngrok_host : config.app_host

      config.url_options = {
          trailing_slash: true,
          protocol:       config.app_protocol,
          host:           config.app_host,
          port:           config.app_port
      }

      config.app_url = "#{config.app_protocol}://#{config.app_host}"
      config.app_url += ":#{config.app_port}" if config.app_port

      config.asset_host = config.app_url
    end
    config.fallback_asset_host = config.app_url
  end
end



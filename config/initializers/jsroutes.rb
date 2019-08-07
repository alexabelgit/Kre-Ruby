JsRoutes.setup do |config|
  config.default_url_options = Rails.configuration.urls_config.url_options
  config.url_links = true
end

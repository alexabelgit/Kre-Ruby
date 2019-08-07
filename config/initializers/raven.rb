Raven.configure do |config|
  config.excluded_exceptions += ['Shopify::ApiWrapper::ShopifyApiLimitError']
end

module Shopify
  class ApiWrapper
    attr_reader :store

    SLEEP_AMOUNT = 2
    SAFE_MARGIN = 3

    API_VERSION = '2019-04'.freeze
    MAX_RETRIES = 20  # used by sync workers, it's ok for some workers to fail due to api call limit usage

    class ShopifyApiLimitError < StandardError; end

    def initialize(store)
      @store = store
    end

    def within_session(call_estimate: 1, try_count: 0)
      try_count+=1
      until enough_calls?(call_estimate)
        sleep SLEEP_AMOUNT
      end

      ShopifyAPI::Session.temp(domain: store.domain, token: store.access_token, api_version: API_VERSION) do
        new_amount = ShopifyAPI.call_count + call_estimate

        $lock.synchronize("lock-store-#{store.id}", initial_wait: 10e-3, increase_wait: true, expiry: 30.seconds, retries: 4000) do
          store.update_shopify_api_usage new_amount
        end

        yield
      end
    rescue ActiveResource::ResourceNotFound => ex
      nil
    rescue ActiveResource::UnauthorizedAccess => ex
      params = { last_sync_error: '401-Unauthorized', last_sync_error_at: DateTime.current, access_token: nil }
      store.update params
      nil
    rescue ActiveResource::ClientError => ex
      error_code = ex.response.code
      error_message = ex.response.message

      if error_code == '429' && try_count <= MAX_RETRIES
        sleep SLEEP_AMOUNT
        retry
      else
        log_api_error "#{error_code}-#{error_message}"
      end
      nil
    rescue ActiveResource::ServerError
      if try_count <= MAX_RETRIES
        sleep SLEEP_AMOUNT
        retry
      end
    rescue JSON::ParserError
      if try_count <= MAX_RETRIES
        sleep SLEEP_AMOUNT
        retry
      end
    end

    private

    def log_api_error(error)
      store.update last_sync_error: error, last_sync_error_at: DateTime.current
    end

    def enough_calls?(amount)
      ShopifyAPI::Session.temp(domain: store.domain, token: store.access_token, api_version: API_VERSION) do
        (ShopifyAPI.available_calls  - amount) > SAFE_MARGIN
      end
    end
  end
end

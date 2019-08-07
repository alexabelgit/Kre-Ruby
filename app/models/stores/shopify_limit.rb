module Stores
  module ShopifyLimit
    extend ActiveSupport::Concern
    SLEEP_AMOUNT = 1

    def shopify_api_limit_exceeded?
      api_usage.limit_exceeded?
    end

    def sleep_and_reduce_limit
      sleep SLEEP_AMOUNT
      api_usage.decrease_by 2
    end

    def update_shopify_api_usage(calls_count)
      api_usage.set calls_count
    end

    def used_limit
      api_usage.current
    end

    private

    def api_usage
      ShopifyApiUsage.new(self.id)
    end
  end
end

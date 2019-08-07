module LemonstandAPI
  class Discount < LemonstandAPI::Base

    def initialize(store, access_token: nil, domain: nil)
      super(store, access_token: access_token, domain: domain, resource_name: :discount)
    end

  end
end

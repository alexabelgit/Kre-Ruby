module LemonstandAPI
  class Order < LemonstandAPI::Base

    def initialize(store, access_token: nil, domain: nil)
      super(store, access_token: access_token, domain: domain, resource_name: :order)
    end

  end
end

module Sync
  class CustomService

    def initialize(store: , provider: nil)
      @store    = store
      @provider = provider || store.provider
    end

    def products(**args)
      []
    end

    def product(**args)
      OpenStruct.new ({ success: false })
    end

    def orders(**args)
      []
    end

    def order(**args)
      OpenStruct.new ({ success: false })
    end

    def validate_order_trigger(**args)
      true
    end

    def customer(**args)
      OpenStruct.new ({ success: false })
    end

  end
end

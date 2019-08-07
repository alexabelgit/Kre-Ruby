module Emails
  class SubscriptionChangedPresenter < BasePresenter
    attr_reader :subscription

    delegate :plan_name, to: :subscription

    def starting_at
      return 'today' if store.shopify?
      store.next_payment_date.strftime('%B %d, %Y')
    end

    def plan_price
      view.number_to_currency(subscription.plan_price.in_dollars)
    end

    def in_plan_products
      "up to #{subscription.products_limit} products"
    end

    def in_plan_orders
      subscription.plan_orders_limit
    end

    def overage_terms
      extension_price = view.number_to_currency(subscription.plan_extension_price_in_dollars)
      "#{subscription.plan_extended_orders_limit} for #{extension_price}"
    end
  end

end
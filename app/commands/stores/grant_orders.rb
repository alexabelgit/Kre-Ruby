module Stores
  class GrantOrders < ApplicationCommand
    object :store
    integer :amount

    def execute
      if store.active_subscription.blank?
        errors.add(:store, "cannot add orders to store without subscription")
        return
      end

      subscription = store.active_subscription
      bundle = subscription.bundle
      latest_gift = bundle.orders_gifts.where(applied_at: subscription.current_billing_cycle).order('applied_at DESC').first

      if latest_gift.present?
        latest_gift.update amount: amount
      else
        OrdersGift.create bundle: bundle, amount: amount, applied_at: DateTime.current
      end
      StoreSubscriptionUsage.refresh
      store
    end
  end
end

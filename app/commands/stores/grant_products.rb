module Stores
  class GrantProducts < ApplicationCommand
    object :store
    integer :amount
    date_time :valid_till, default: nil

    def execute
      unless store.subscription?
        errors.add(:store, "cannot add orders to store without subscription")
        return
      end

      subscription = store.active_subscription
      subscription.update gifted_products_amount: amount, gifted_products_valid_till: valid_till
      store
    end
  end
end
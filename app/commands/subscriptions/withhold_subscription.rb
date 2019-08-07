module Subscriptions
  class WithholdSubscription < ApplicationCommand
    object :subscription

    def execute
      return if subscription.real?

      subscription.withhold!
      BackMailer.free_plan_withheld(subscription.store.id).deliver
    end
  end
end

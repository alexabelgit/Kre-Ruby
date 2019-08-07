module Subscriptions
  class ReleaseSubscriptionHold < ApplicationCommand
    object :subscription

    def execute
      return if subscription.real?

      subscription.release_hold!
    end
  end
end
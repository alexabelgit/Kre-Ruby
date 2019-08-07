module Subscriptions
  class AbortSubscription < ApplicationCommand
    object :subscription

    def execute
      unless subscription.pending? || subscription.gifted?
        errors.add(:subscription, 'Cannot abort subscription. Processing, suspended or active subscription can only be cancelled, not aborted')
        return subscription
      end

      successful = subscription.bundle.destroy && subscription.destroy

      successful ? Result.new(success: true, status: :cleaned_up) : subscription
    end
  end
end

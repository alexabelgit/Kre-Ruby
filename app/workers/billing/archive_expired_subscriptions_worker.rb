require 'sidekiq-scheduler'

module Billing
  class ArchiveExpiredSubscriptionsWorker
    include Sidekiq::Worker
    sidekiq_options queue: :default

    def perform
      Subscription.to_be_archived.find_each do |subscription|
        bundle = subscription.bundle
        bundle.outdate! if bundle&.active?

        subscription.archive!
      end
    end
  end
end

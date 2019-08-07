class ArchiveExpiredSubscriptions < ApplicationJob
  queue_as :default

  ### SIDEKIQED

  def perform
    Subscription.to_be_archived.find_each do |subscription|
      bundle = subscription.bundle
      bundle.outdate! if bundle&.active?

      subscription.archive!
    end
  end
end

class HoldReviewRequestsWorker
  include Sidekiq::Worker
  sidekiq_options queue: :high, retry: 3

  def perform(store_id)
    store = Store.find_by_id(store_id)
    return unless store.present?

    store.review_requests.where(status: [:scheduled, :pending, :incomplete]).where.not(scheduled_for: nil).each do |review_request|
      review_request.hold!
    end
  end
end

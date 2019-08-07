class HoldReviewRequestsJob < ApplicationJob
  queue_as :high

  ### SIDEKIQED  

  def perform(store_id)
    store = Store.find_by_id(store_id)
    return unless store.present?

    store.review_requests.where(status: [:scheduled, :pending, :incomplete]).where.not(scheduled_for: nil).each do |review_request|
      review_request.update_attributes(scheduled_for: nil)
      review_request.on_hold! if review_request.scheduled?
    end
  end
end

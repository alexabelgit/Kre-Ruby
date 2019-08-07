class ProceedOnHoldReviewRequestsWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default

  def perform(store_id)
    store = Store.find_by_id(store_id)
    return unless store.present?

    store.review_requests.on_hold.each do |review_request|
      review_request.update_columns(scheduled_for: DateTime.current)
      review_request.proceed
    end
    store.settings(:background_workers).update_attributes(proceed_on_hold_review_requests_running: false)
  end
end

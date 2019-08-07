class SendReviewRequestWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default

  def perform(id, model_name = Order.name)
    if model_name == Order.name
      order = Order.find_by_id(id)
      review_request = order.review_request if order.present?
    elsif model_name == ReviewRequest.name
      review_request = ReviewRequest.find_by_id(id)
    end
    return unless review_request.present?
    Time.zone = review_request.store.time_zone
    review_request.proceed
  end
end

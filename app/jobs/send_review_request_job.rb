class SendReviewRequestJob < ApplicationJob
  queue_as :default

  ### SIDEKIQED

  def perform(order_id)
    order = Order.find_by_id(order_id)
    Time.zone = order.store.time_zone
    order.review_request.proceed
  end
end

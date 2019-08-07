# frozen_string_literal: true

require 'test_helper'

class FrontMailerTest < ActionMailer::TestCase
  let(:uid) { 123_456 }

  describe '#review_request' do
    let(:store)    { create :store }
    let(:customer) { create :customer, store: store }
    let(:product)  { create :product, store: store }
    let(:order)    { create :order, customer: customer }

    test 'please review mail delivered' do
      review_request = ReviewRequests::CreateReviewRequest.run(customer: customer, order: order, product_ids: [product.id]).result

      store.settings(:global).restrict_outgoing_emails = false

      FrontMailer.review_request(review_request, uid).deliver
      delivered_email = ActionMailer::Base.deliveries.last
      assert_includes delivered_email.to, review_request.customer.email
    end
  end
end

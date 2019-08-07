require 'test_helper'

class AbuseReportTest < ActiveSupport::TestCase
  describe '#inappropriate_content_type' do
    test 'is abusable type for most cases' do
      store = create :store
      product = create :product, store: store
      customer = create :customer, store: store
      review = Reviews::CreateReview.run(reviewables: [product], customer: customer, rating: 3, feedback: 'test_feedback').result
      abuse_report = described_class.new abusable: review

      assert_equal 'Review', abuse_report.inappropriate_content_type
    end

    test 'equals Q&A for questions' do
      question = create :question
      abuse_report = described_class.new abusable: question

      assert_equal 'Q&A', abuse_report.inappropriate_content_type
    end
  end

  test '#user_email returns user email' do
    store = fake :store, user_email: 'some@email.com'
    product = build :product, store: store
    question = build :question, product: product
    abuse_report = described_class.new abusable: question

    assert_equal 'some@email.com', abuse_report.user_email
  end
end

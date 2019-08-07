require 'test_helper'

module Admin
  class ReviewsControllerTest < ActionDispatch::IntegrationTest

    setup do
      admin = create :admin
      sign_in admin
    end

    describe 'GET #index' do
      it 'responds with success' do
        get admin_reviews_url
        assert_response :success
      end
    end

    describe 'GET #show' do
      setup do
        user = create :user
        store = create :store, user: user
        product = create :product, store: store
        customer = create :customer, store: store
        @review = Reviews::CreateReview.run(reviewables: [product], customer: customer, rating: 3, feedback: 'test_feedback').result
      end

      test "responds with success" do
        get admin_review_url(@review)
        assert_response :success
      end
    end
  end
end

require 'test_helper'

class ReviewTest < ActiveSupport::TestCase

  test '#user_email returns store user email' do
    user = create :user, email: 'some@email.com'
    store = create :store, user: user
    product = build :product, store: store
    customer = build :customer, store: store
    review = Reviews::CreateReview.run(reviewables: [product], customer: customer, rating: 3, feedback: 'test_feedback').result

    assert_equal 'some@email.com', review.user_email
  end

  test '#product_name returns product name' do
    user = create :user
    store = create :store, user: user
    product = build :product, name: 'Black dress'
    customer = build :customer, store: store
    review = Reviews::CreateReview.run(reviewables: [product], customer: customer, rating: 3, feedback: 'test_feedback').result

    assert_equal 'Black dress', review.product_name
  end

  test 'review should not published if ratings is less than 4' do
    user = create :user
    store = create :store, user: user
    product = build :product, name: 'Black dress'
    customer = build :customer, store: store
    store.store.settings(:reviews).update_attributes!(auto_publish: true, minimum_ratings_to_publish: 4)
    review = Reviews::CreateReview.run(reviewables: [product], customer: customer, rating: 3, feedback: 'test_feedback').result

    assert !review.published?
  end

  test 'review should not published if ratings is greater than 4 but store auto published check is disabled' do
    user = create :user
    store = create :store, user: user
    product = build :product, name: 'Black dress'
    customer = build :customer, store: store
    store.store.settings(:reviews).update_attributes!(auto_publish: false, minimum_ratings_to_publish: 4)
    review = Reviews::CreateReview.run(reviewables: [product], customer: customer, rating: 5, feedback: 'test_feedback').result

    assert !review.published?
  end

  test 'review should published if ratings is greate than or equal to 4' do
    user = create :user
    store = create :store, user: user
    product = build :product, name: 'Black dress'
    customer = build :customer, store: store
    store.store.settings(:reviews).update_attributes!(auto_publish: true, minimum_ratings_to_publish: 4)
    review = Reviews::CreateReview.run(reviewables: [product], customer: customer, rating: 4, feedback: 'test_feedback').result

    assert review.published?
  end
end

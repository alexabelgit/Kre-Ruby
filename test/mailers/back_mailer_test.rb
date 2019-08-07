# frozen_string_literal: true

require 'test_helper'

class BackMailerTest < ActionMailer::TestCase
  let(:user) { create :user }
  let(:store) { create :store, user: user }
  let(:product) { create :product, store: store }
  let(:customer) { create :customer, store: store }

  describe '#pending' do
    let(:attributes) { { reviewables: [product], customer: customer, rating: 3, feedback: 'test_feedback' } }
    let(:review) { Reviews::CreateReview.run(attributes).result }

    test 'delivers successfully' do

      pending_email = BackMailer.pending(review)

      assert_emails 1 do
        pending_email.deliver!
      end

      assert_includes pending_email.to, user.email
    end
  end

  describe '#flagged_review' do
    let(:attributes) { { reviewables: [product], customer: customer, rating: 3, feedback: 'test_feedback' } }
    let(:review) { Reviews::CreateReview.run(attributes).result }

    test 'delivers successfully' do
      create :flag, flaggable: review

      flagged_review_email = BackMailer.flagged_review(review)

      assert_emails 1 do
        flagged_review_email.deliver!
      end

      assert_includes flagged_review_email.to, user.email
    end
  end

  describe '#trial_finished' do
    test 'delivers successfully' do
      trial_finished_email = BackMailer.trial_finished(store.id)
      assert_emails 1 do
        trial_finished_email.deliver!
      end

      assert_includes trial_finished_email.to, user.email
    end
  end

  describe '#trial_ending' do
    test 'delivers successfully' do
      trial_ending_email = BackMailer.trial_ending(store.id)
      assert_emails 1 do
        trial_ending_email.deliver!
      end

      assert_includes trial_ending_email.to, user.email
    end
  end

  describe '#grace_period_ended' do
    test 'delivers successfully' do
      grace_period_ended_email = BackMailer.grace_period_ended(store.id)
      assert_emails 1 do
        grace_period_ended_email.deliver!
      end

      assert_includes grace_period_ended_email.to, user.email
    end
  end
end

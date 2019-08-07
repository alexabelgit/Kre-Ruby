require 'test_helper'

module Subscriptions
  class CancelSubscriptionTest < ActiveSupport::TestCase

    let(:subscription) { create :subscription, :active }

    before do
      Timecop.freeze
    end

    test 'responds with success' do
      outcome = described_class.run subscription: subscription
      assert outcome.valid?
    end

    describe 'when subscription is shopify' do
      before do
        store = create :store, ecommerce_platform: EcommercePlatform.shopify
        bundle = create :bundle, :active, store: store
        @subscription = create :subscription, :active, bundle: bundle
      end

      test 'cancels subscription' do
        outcome = described_class.run subscription: @subscription
        assert @subscription.reload.cancelled?
      end
    end

    describe 'when subscription is processed by chargebee' do
      before do
        store = create :store, ecommerce_platform: EcommercePlatform.ecwid
        bundle = create :bundle, :active, store: store
        @subscription = create :subscription, :active, bundle: bundle
      end

      test 'stops subscription renewal' do
        outcome = described_class.run subscription: @subscription
        assert @subscription.reload.non_renewing?
      end
    end

    describe 'when subscription could not be cancelled' do
      test 'responds with error' do
        subscription = build :subscription, state: :pending
        outcome = described_class.run subscription: subscription
        refute outcome.valid?
        assert_includes outcome.errors.full_messages, 'Subscription cannot be cancelled'
      end
    end

    describe 'when stop_recurring_charges is truthy' do
      test 'cancels payments via API' do
        command = described_class.new subscription: subscription, stop_recurring_charges: true

        recurring_charge = fake(:recurring_charge) { Payments::RecurringCharge }
        stub(command).payments_service { recurring_charge }

        command.execute
        assert_received recurring_charge, :cancel, []
      end
    end

    describe 'when cancellation date passed' do
      test 'expires subscription at given date' do
        cancellation_date = 5.days.ago.to_datetime
        outcome = described_class.run subscription: subscription, cancelled_at: cancellation_date

        cancelled_on = subscription.reload.cancelled_on

        assert_equal cancellation_date.to_s, cancelled_on.to_datetime.to_s
      end
    end

    describe 'when no cancellation date passed' do
      test 'cancels subscription immediately' do
        subscription = create :subscription, :active
        assert_nil subscription.cancelled_on

        outcome = described_class.run subscription: subscription

        cancelled_on = subscription.reload.cancelled_on
        assert_equal DateTime.current.to_s, cancelled_on.to_datetime.to_s
      end
    end
  end
end

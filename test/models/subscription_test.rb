require 'test_helper'

class SubscriptionTest < ActiveSupport::TestCase

  teardown do
    Timecop.return
  end

  describe '#dunning?' do
    test 'subscription is dunning when its active and has due charges' do
      sub = build :subscription, :active

      refute sub.dunning?
      sub.update total_due: 299
      assert sub.dunning?
    end
  end

  describe 'when activating subscription' do
    let(:bundle) { create :bundle, :processing }

    test 'cannot activate just initialized subscription' do
      subscription = described_class.new state: :initialized, bundle: bundle
      refute_event_allowed subscription, :activate

      assert_transitions_from subscription, :pending, to: :active, on_event: :activate
    end
  end
end

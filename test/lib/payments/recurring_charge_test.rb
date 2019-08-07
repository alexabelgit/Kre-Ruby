require 'test_helper'

module Payments
  class RecurringChargeTest < ActiveSupport::TestCase

    describe '#cancel' do
      let(:subscription) { build :subscription }

      test 'raises an abstract class exception' do
        subject = described_class.new subscription
        assert_raises do
          subject.cancel
        end
      end
    end
  end
end

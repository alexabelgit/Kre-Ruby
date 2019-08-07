require 'test_helper'

module Shopify
  class PaymentResultParserTest < ActiveSupport::TestCase

    describe '#state' do
      let(:payment_result) { OpenStruct.new activated_on: Time.current, accepted_on: Time.current, status: 'active' }

      test 'converts payment status to subscription state' do
        parser = described_class.new payment_result
        assert_equal :active, parser.state
      end

      test 'returns nil when cannot find matching state' do
        result = OpenStruct.new status: "strange_status"
        parser = described_class.new result
        assert_nil parser.state
      end
    end
  end
end

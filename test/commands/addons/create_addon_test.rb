require 'test_helper'

module Addons
  class CreateAddonTest < ActiveSupport::TestCase
    include ActiveInteractonsHelpers

    let(:inputs) { { name: 'Social push', description: 'Test' } }

    test 'executes successfully' do
      action = described_class.new inputs
      outcome = action.execute
      assert outcome.valid?
    end

    test 'creates addon with given params' do
      action = described_class.new inputs
      assert_difference 'Addon.count', +1 do
        action.execute
      end
    end

    describe 'when prices hash passed' do
      before do
        @shopify = FactoryBot.create :ecommerce_platform, name: 'shopify'
        @ecwid = FactoryBot.create :ecommerce_platform, name: 'ecwid'
        @set_price = fake(AddonPrices::SetNewAddonPrice, run: ValidOutcome.new, as: :class)
      end

      test 'sets new addon price for each passed platform' do
        inputs = { name: 'Social push', prices: { shopify: 1.99, ecwid: 2.99} }
        action = described_class.new inputs
        stub(action).new_price_command { @set_price }

        addon = action.execute

        assert_received @set_price, :run, [{ ecommerce_platform: @shopify, price: 1.99, addon: addon }]
        assert_received @set_price, :run, [{ ecommerce_platform: @ecwid, price: 2.99, addon: addon }]
      end
    end

  end
end

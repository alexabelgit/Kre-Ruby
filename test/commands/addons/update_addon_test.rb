require 'test_helper'

module Addons
  class UpdateAddonTest < ActiveSupport::TestCase
    include ActiveInteractonsHelpers

    let(:addon) { create :addon }

    test 'updates addons name and description' do
      inputs = { addon: addon, name: 'New name', description: 'Desc'}
      action = described_class.new inputs

      outcome = action.execute

      assert_equal 'New name', addon.name
      assert_equal 'Desc', addon.description
    end

    test 'can change state manually' do
      inputs = { addon: addon, state: :active }
      action = described_class.new inputs

      addon = action.execute
      assert addon.active?
    end

    describe 'when prices hash passed' do
      before do
        @shopify = FactoryBot.create :ecommerce_platform, name: 'shopify'
        @ecwid = FactoryBot.create :ecommerce_platform, name: 'ecwid'
        @set_price = fake(AddonPrices::SetNewAddonPrice, run: ValidOutcome.new, as: :class)
      end

      test 'sets new addon price for each passed platform' do
        inputs = { addon: addon, prices: { shopify: 1.99, ecwid: 2.99} }
        action = described_class.new inputs
        stub(action).new_price_command { @set_price }

        addon = action.execute

        assert_received @set_price, :run, [{ ecommerce_platform: @shopify, price: 1.99, addon: addon }]
        assert_received @set_price, :run, [{ ecommerce_platform: @ecwid, price: 2.99, addon: addon }]
      end
    end

  end
end

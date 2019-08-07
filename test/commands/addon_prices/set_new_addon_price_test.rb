require 'test_helper'
module AddonPrices
  class SetNewAddonPriceTest < ActiveSupport::TestCase
    let(:addon) { create :addon }
    let(:platform) { create :ecommerce_platform }
    let(:params){ { addon: addon, ecommerce_platform: platform, price: 1.99 } }

    test 'executes successfully' do
      command = described_class.new params
      outcome = command.execute
      assert outcome.valid?
    end

    test 'creates new price for addon' do
      command = described_class.new params
      assert_difference 'addon.addon_prices.count' do
        command.execute
      end
    end

    describe 'when addon already has price' do
      before do
        @old_price = create :addon_price, addon: addon, ecommerce_platform: platform, price_in_cents: 99
      end

      test 'deprecates old price' do
        assert @old_price.actual?
        command = described_class.new params
        command.execute
        refute @old_price.reload.actual?, 'Old price is not actual any more'
        assert @old_price.reload.deprecated?
      end
    end

    test 'price is converted to cents before saving' do
      command = described_class.new params
      addon_price = command.execute
      assert_equal 199, addon_price.price_in_cents
    end
  end
end

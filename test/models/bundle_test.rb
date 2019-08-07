require 'test_helper'

class BundleTest < ActiveSupport::TestCase
  let(:bundle) { described_class.new }

  before do
    stub(bundle).addons_enabled? { false }
  end

  test '#total_price is base plan price and addons price with discount' do
    stub(bundle).plan_price { 10 }
    stub(bundle).addons_price { 3 }
    assert_equal 13, bundle.total_price
  end

  test '#dollars_price returns price in dollars' do
    stub(bundle).total_price { 799 }
    assert_equal 7.99, bundle.dollars_price
  end

  test '#raw_price is base plan price and addons price without discount' do
    stub(bundle).plan_price { 399 }
    stub(bundle).raw_addons_price { 199 }

    assert_equal 199 + 399, bundle.raw_price
  end

  test '#raw_addons_price is 0 when addons feature disabled' do
    stub(bundle).addon_prices do
      [ fake(:addon_price, price_in_cents: 199),
        fake(:addon_price, price_in_cents: 299),
        fake(:addon_price, price_in_cents: 99)
      ]
    end

    assert_equal 0, bundle.raw_addons_price
  end

  test '#raw_addons_price is total price of all addons' do
    stub(bundle).addons_enabled? { true }
    stub(bundle).addon_prices do
      [ fake(:addon_price, price_in_cents: 199),
        fake(:addon_price, price_in_cents: 299),
        fake(:addon_price, price_in_cents: 99)
      ]
    end

    assert_equal 99 + 199 + 299, bundle.raw_addons_price
  end

  test '#addons_price is price of all addons with discount' do
    stub(bundle).raw_addons_price { 199 }
    stub(bundle).discount_amount { 99 }

    assert_equal 199 - 99, bundle.addons_price
  end

  describe '#plan_price' do
    let(:plan_name) { 'Boxful' }
    let(:ecommerce_platform) { create :ecommerce_platform }
    let(:bundle)  { create :bundle }
    test 'returns latest bundle price' do
      actual_plan = create :plan, name: plan_name,
                           ecommerce_platform: ecommerce_platform, price_in_cents: 499
      create :bundle_item, bundle: bundle, price_entry: actual_plan
      assert_equal 499, bundle.plan_price
    end

    test 'returns even deprecated plan' do
      deprecated_plan = create :plan, name: plan_name,
                               ecommerce_platform: ecommerce_platform, price_in_cents: 999,
                               deprecated_at: DateTime.now
      create :plan, name: plan_name, ecommerce_platform: ecommerce_platform, price_in_cents: 499
      create :bundle_item, bundle: bundle, price_entry: deprecated_plan
      assert_equal 999, bundle.plan_price
    end
  end

  describe '#summary' do
    setup do
      stub(bundle).plan_name { 'Essential' }
    end

    test 'based on amount of addons' do
      stub(bundle).addon_prices { Array.new(3) }
      assert_equal "Essential + 3 add-ons", bundle.summary
    end

    test 'pluralized correctly' do
      stub(bundle).addon_prices { Array.new(1) }
      assert_equal "Essential + 1 add-on", bundle.summary
    end

    context 'when has zero addons' do
      test 'is just a basic plan name' do
        stub(bundle).addon_prices { [] }
        assert_equal 'Essential', bundle.summary
      end
    end
  end
end

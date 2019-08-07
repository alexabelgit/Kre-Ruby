require 'test_helper'

module PackageDiscounts
  class CreatePackageDiscountTest < ActiveSupport::TestCase
    setup do
      @shopify = EcommercePlatform.shopify
    end

    let(:addons_count) { 2 }
    let(:inputs) do
      { ecommerce_platform: @shopify,
        addons_count: addons_count,
        discount_percents: 10,
        chargebee_id: '2-ADDONS-DISCOUNT' }
    end

    test 'executes successfully' do
      command = described_class.new inputs

      outcome = command.execute
      assert outcome.valid?
    end

    test 'creates package discount' do
      command = described_class.new inputs

      assert_difference 'PackageDiscount.count', +1 do
        command.execute
      end
    end

    test 'discount percents value should be positive' do
      negative_discount = inputs.merge(discount_percents: -10)

      outcome = described_class.run negative_discount
      refute outcome.valid?

      zero_discount = inputs.merge(discount_percents: 0)
      outcome = described_class.run zero_discount

      refute outcome.valid?
    end

    test 'deprecates previous discount' do
      old_discount = PackageDiscount.create ecommerce_platform: @shopify,
                                            addons_count: addons_count,
                                            discount_percents: 15
      assert old_discount.actual?

      described_class.run inputs
      assert old_discount.reload.deprecated?
    end
  end
end

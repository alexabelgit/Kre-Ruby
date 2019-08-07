require 'test_helper'

module PackageDiscounts
  class DestroyPackageDiscountTest < ActiveSupport::TestCase

    setup do
      @package_discount = create :package_discount
    end

    let(:inputs) { { package_discount: @package_discount} }

    describe 'when does not have applied discounts' do
      test 'destroys given package discount' do
        assert_difference 'PackageDiscount.count', -1 do
          described_class.run inputs
        end
      end

      test 'executes successfully' do
        outcome = described_class.run inputs
        assert outcome.valid?
      end
    end

    describe 'when has applied discounts' do
      setup do
        create :applied_discount, package_discount: @package_discount
      end

      test 'responds with error' do
        outcome = described_class.run inputs
        refute outcome.valid?

        error = 'Package discount has applied discounts and could only be deprecated'
        assert_equal error, outcome.errors.full_messages.to_sentence
      end

      test 'does not destroy record' do
        assert_no_difference 'PackageDiscount.count' do
          described_class.run inputs
        end
      end
    end
  end
end

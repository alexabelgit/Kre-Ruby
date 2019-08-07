require 'test_helper'

class Plan::OverageChargeTest < ActiveSupport::TestCase

  let(:store) { create :store }
  let(:bundle) { create :bundle, store: store, state: :active }

  setup do
    Timecop.freeze
  end

  describe '#description' do
    it 'is empty when plan is not present' do
      subscription = build :subscription, bundle: bundle

      charge = described_class.new subscription
      assert_equal '', charge.description
    end

    it 'is empty when plan is not extensible' do
      create_plan quota: nil
      subscription = build :subscription, bundle: bundle

      charge = described_class.new subscription
      assert_equal '', charge.description
    end

    it 'gives charge description' do
      create_plan quota: 10, extension_price: 100, extension_amount: 20
      subscription = build :subscription, bundle: bundle

      charge = described_class.new subscription
      stub(charge).orders_over_quota { 30 }

      assert_equal "$2.00 for 30 orders over plan limit", charge.description
    end
  end

  describe 'amount' do
    before do
      create_plan quota: 10, extension_price: 100, extension_amount: 20
      @subscription = build :subscription, bundle: bundle
    end

    it 'bills full extension price even for 1 order over quota' do
      charge = described_class.new @subscription

      stub(charge).orders_over_quota { 1 }
      assert_equal 100, charge.amount
    end

    it 'calculates charge amount based on order over quota' do
      charge = described_class.new @subscription
      stub(charge).orders_over_quota { 100 }
      assert_equal 500, charge.amount
    end

    it 'returns 0 when no orders over quota' do
      charge = described_class.new @subscription
      stub(charge).orders_over_quota { 0 }

      assert_equal 0, charge.amount
    end
  end

  describe '#orders_over_quota' do
    describe 'when plan is not present' do
      it 'returns 0' do
        subscription = build :subscription, bundle: bundle

        charge = described_class.new subscription
        assert_equal 0, charge.orders_over_quota
      end
    end

    describe 'when plan is not extensible' do
      it 'returns 0' do
        create_plan quota: nil
        subscription = build :subscription, bundle: bundle

        charge = described_class.new subscription
        assert_equal 0, charge.orders_over_quota
      end
    end

    it 'counts orders over quota within billing cycle' do
      create_plan quota: 2, extension_price: 100, extension_amount: 20
      subscription = create :subscription, bundle: bundle, next_billing_at: 20.days.from_now, state: :active

      customer = create :customer, store: store
      create_list :order, 5, customer: customer, order_date: 1.day.ago
      create :order, customer: customer, order_date: 2.months.ago

      charge = described_class.new subscription

      assert_equal 3, charge.orders_over_quota
    end
  end

  def create_plan(quota: nil, extension_price: nil, extension_amount: nil)
    plan = create :plan, orders_limit: quota, extension_price_in_cents: extension_price, extended_orders_limit: extension_amount
    create :bundle_item, bundle: bundle, price_entry: plan
  end
end

require 'test_helper'
require_relative './stores/billable_test'

class StoreTest < ActiveSupport::TestCase
  include Stores::BillableTest

  setup do
    @store = Store.new
    Timecop.freeze
  end

  def create_store_with_products_and_reviews
    store = create :store
    product = create :product, store: store
    customer = create :customer, store: store
    @review = Reviews::CreateReview.run(reviewables: [product], customer: customer, rating: 3, feedback: 'test_feedback').result

    store
  end

  describe '#provider' do
    test 'returns ecommerce platform name' do
      store = build :store, ecommerce_platform: EcommercePlatform.shopify
      assert_equal 'shopify', store.provider
      store.ecommerce_platform = EcommercePlatform.ecwid
      assert_equal 'ecwid', store.provider
    end

    test 'is nil when ecommerce platform nil' do
      store = build :store, ecommerce_platform: nil
      assert_nil store.provider
    end
  end

  test 'shopify? is true when ecommerce platform is shopify' do
    store = build :store, ecommerce_platform: EcommercePlatform.ecwid
    refute store.shopify?
    store.ecommerce_platform = EcommercePlatform.shopify
    assert store.shopify?
  end

  test 'ecwid? is true when ecommerce platform is ecwid' do
    store = build :store, ecommerce_platform: EcommercePlatform.shopify
    refute store.ecwid?
    store.ecommerce_platform = EcommercePlatform.ecwid
    assert store.ecwid?
  end

  test 'custom? is true when ecommerce platform is custom' do
    store = build :store, ecommerce_platform: EcommercePlatform.ecwid
    refute store.custom?
    store.ecommerce_platform = EcommercePlatform.custom
    assert store.custom?
  end

  test '.shopify returns all stores that have shopify provider' do
    shopify_1, shopify_2 = create_list :store, 2, ecommerce_platform: EcommercePlatform.shopify
    ecwid_1, ecwid_2 = create_list :store, 2, ecommerce_platform: EcommercePlatform.ecwid
    custom_1 = create :store, ecommerce_platform: EcommercePlatform.custom
    assert_same_elements [shopify_1, shopify_2], Store.shopify
  end

  test '.ecwid returns all stores that have ecwid provider' do
    shopify_1, shopify_2 = create_list :store, 2, ecommerce_platform: EcommercePlatform.shopify
    ecwid_1, ecwid_2 = create_list :store, 2, ecommerce_platform: EcommercePlatform.ecwid
    custom_1 = create :store, ecommerce_platform: EcommercePlatform.custom
    assert_same_elements [ecwid_1, ecwid_2], Store.ecwid
  end

  test '.custom returns all stores that have custom provider' do
    shopify_1, shopify_2 = create_list :store, 2, ecommerce_platform: EcommercePlatform.shopify
    ecwid_1, ecwid_2 = create_list :store, 2, ecommerce_platform: EcommercePlatform.ecwid
    custom_1 = create :store, ecommerce_platform: EcommercePlatform.custom
    assert_same_elements [custom_1], Store.custom.to_a
  end

  test 'hierarchical structure is correct' do
    store = create_store_with_products_and_reviews

    assert store.reviews.count > 0, 'Store-Reviews exist'
    assert_equal store.reviews.count, Review.count, 'Store-Reviews relation'
    assert store.products.count > 0, 'Store-Products exist'
    assert_equal store.products.count, Product.count, 'Store-Products relation'
    assert store.customers.count > 0, 'Store-Customers exist'
    assert_equal store.customers.count, Customer.count, 'Store-Customers relation'

    store.destroy

    assert_equal 0, Review.count, 'Store-Reviews dependent on destroy'
    assert_equal 0, Product.count, 'Store-Products dependent on destroy'
    assert_equal 0, Order.count, 'Store-Orders dependent on destroy'
    assert_equal 0, Customer.count, 'Store-Customers dependent on destroy'
  end

  test '#user_email returns user email' do
    user = build :user, email: 'some@email.com'
    store = build :store
    store.user = user

    assert_equal 'some@email.com', store.user_email
  end

  describe '#active_bundle' do
    before do
      @store = create :store
    end

    test 'fetches latest active bundle' do
      processing_bundle = create :bundle, :processing, store: @store
      disabled_bundle = create :bundle, :disabled, store: @store
      active_bundle = create :bundle, :active, store: @store

      assert_equal active_bundle, @store.active_bundle
    end
  end

  describe '#plan_price' do
    test 'is plan price of active bundle' do
      bundle = fake(:bundle, plan_price: 499)
      store = build :store
      stub(store).active_bundle { bundle }

      assert_equal 499, store.plan_price
    end

    describe 'when store does not have active bundle' do
      before do
        @platform = create :ecommerce_platform, name: 'shopify'
        @store = create :store, ecommerce_platform: @platform
      end

      test 'it tries to get price from processing bundle' do
        processing_bundle = create :bundle, state: 'processing', store: @store
        plan = create :plan, ecommerce_platform: @platform, price_in_cents: 399
        create :bundle_item, bundle: processing_bundle, price_entry: plan

        assert_equal 399, @store.plan_price
      end

      test 'it tries to fetch price from latest disabled bundle' do
        disabled_bundle = create :bundle, state: 'disabled', store: @store
        plan = create :plan, ecommerce_platform: @platform, price_in_cents: 199
        create :bundle_item, bundle: disabled_bundle, price_entry: plan
        assert_equal 199, @store.plan_price
      end

      test 'it is plan price for store ecommerce platform' do
        create :plan, ecommerce_platform: @platform, price_in_cents: 199
        stub(@store).active_bundle { nil }

        assert_equal 199, @store.plan_price
      end
    end

    describe 'when does not have bundle and price for platofm is not defined' do
      test 'returns zero' do
        store = build :store
        assert_equal 0, store.plan_price
      end
    end
  end
end

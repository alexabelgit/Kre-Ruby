require 'test_helper'
module Payments
  class UpdateSubscriptionParamsBuilderTest < ActiveSupport::TestCase
    let(:store) { create :store, ecommerce_platform: ecwid }

    # ecommerce platform
    let(:ecwid) { create :ecommerce_platform, name: 'Ecwid' }

    # plans
    let(:essential) { create :plan, name: 'Essential', slug: :essential, price_in_cents: 399, chargebee_id: :essential, ecommerce_platform: ecwid }
    let(:growth) { create :plan, name: 'Growth', slug: :growth, price_in_cents: 999, chargebee_id: :growth, ecommerce_platform: ecwid }

    # addons
    let(:media_reviews) { create :addon, name: 'Media reviews', slug: :media_reviews }
    let(:media_reviews_price) { create :addon_price, addon: media_reviews, price_in_cents: 499, ecommerce_platform: ecwid, chargebee_id: :media_reviews }

    let(:product_groups) { create :addon, name: 'Product groups', slug: :product_groups }
    let(:product_groups_price) { create :addon_price, addon: product_groups, price_in_cents: 499, ecommerce_platform: ecwid, chargebee_id: :product_groups }

    let(:unlimited_reviews) { create :addon, name: 'Unlimited reviews', slug: :unlimited_reviews }
    let(:unlimited_reviews_price) { create :addon_price, addon: unlimited_reviews, price_in_cents: 499, ecommerce_platform: ecwid, chargebee_id: :unlimited_reviews }

    setup do
      essential
      growth
      product_groups_price
      media_reviews_price
      unlimited_reviews_price
    end

    def create_bundle(plan_slug, addons)
      bundle = create :bundle, store: store
      bp = Plan.find_by slug: plan_slug
      create :bundle_item, price_entry: bp, bundle: bundle

      addons = Addon.where(slug: addons)
      prices = AddonPrice.where(addon: addons)
      prices.each do |price|
        create :bundle_item, bundle: bundle, price_entry: price
      end
      bundle
    end

    test 'properly calculates upgrade params' do
      old_bundle = create_bundle :essential, [:media_reviews, :unlimited_reviews]
      new_bundle = create_bundle :growth, [:product_groups, :unlimited_reviews]

      subject = described_class.new new_bundle, old_bundle

      expected = { plan_id: 'growth',
                   addons: [
                     { id: 'product_groups' }
                   ]
                 }

      assert_equal expected, subject.upgrade_params
    end

    test 'properly calculates downgrade params' do
      old_bundle = create_bundle :growth, [:product_groups, :unlimited_reviews]
      new_bundle = create_bundle :essential, [:media_reviews, :unlimited_reviews]

      subject = described_class.new new_bundle, old_bundle
      expected = { plan_id: 'essential',
                   addons: [
                     { id: 'media_reviews' },
                     { id: 'unlimited_reviews'}
                   ]
                 }
      assert_equal expected, subject.downgrade_params
    end
  end
end

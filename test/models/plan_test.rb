require 'test_helper'

class PlanTest < ActiveSupport::TestCase

  test 'is deprecated when deprecated_at present' do
    addon_price = described_class.new deprecated_at: nil
    refute addon_price.deprecated?

    addon_price.deprecated_at = Time.zone.now
    assert addon_price.deprecated?
  end

  test 'is actual when not deprecated' do
    addon_price = described_class.new deprecated_at: nil
    assert addon_price.actual?

    addon_price.deprecated_at = Time.zone.now
    refute addon_price.actual?
  end

  test 'adds slug to created plan' do
    plan = described_class.new name: 'Business Growth'
    assert_nil plan.slug

    plan.save
    assert_equal 'business_growth', plan.slug
  end
end

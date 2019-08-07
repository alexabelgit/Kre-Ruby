require 'test_helper'

class AddonPriceTest < ActiveSupport::TestCase

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
end

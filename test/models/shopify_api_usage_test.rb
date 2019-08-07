require 'test_helper'

class ShopifyApiUsageTest < ActiveSupport::TestCase

  STORE_ID = 111
  subject { described_class.new(STORE_ID) }

  after do
    subject.clear
  end

  test 'could set value to given amount and retrieve it' do
    subject.set 10
    assert_equal 10, subject.current
  end

  test 'when no value is stored - set it to 0 and returns 0' do
    assert_equal 0, subject.current
  end

  test '#decrease_by returns value by given amount' do
    subject.set 20
    assert_equal 20, subject.current
    subject.decrease_by 6
    assert_equal 14, subject.current
  end

  test '#limit_exceeded? is true when current value over limit' do
    subject.set 29
    refute subject.limit_exceeded?

    subject.set 35
    assert subject.limit_exceeded?
  end
end

require 'test_helper'

class StoreTrialPresenterTest < ActiveSupport::TestCase
  let(:store) { build :store }

  test '#total_trial_duration returns trial duration in days' do
    stub(store).total_trial_duration { 15.days }
    presenter = described_class.new store

    assert_equal '15 days', presenter.total_trial_duration
  end

  test '#trial_expiring_in gets returns days left before trial finish when we send first email' do
    presenter = described_class.new store
    assert_equal '3 days', presenter.trial_expiring_in
  end

  test '#plan_price is store base price in dollars' do
    stub(store).plan_price { 499 }
    presenter = described_class.new store

    assert_equal '$4.99', presenter.plan_price
  end

  test '#user_first_name is first name of store owner' do
    user = fake(:user, first_name: 'Mike')
    stub(store).user { user }

    presenter = described_class.new store
    assert_equal 'Mike', presenter.user_first_name
  end

  test'#formatted_trial_name says how many days of trial left' do
    stub(store).total_trial_duration { 90.days }
    presenter = described_class.new store
    assert_equal '90-day', presenter.formatted_trial_name
  end

  test '#formatted_trial_name works even if we set trial to years' do
    stub(store).total_trial_duration { 2.years }
    presenter = described_class.new store
    assert_equal '2-year', presenter.formatted_trial_name
  end

  test '#formatted_trial_name produces long version for complex duration' do
    stub(store).total_trial_duration { 1.year + 3.months + 6.days }
    presenter = described_class.new store
    assert_equal '1 year, 3 months, and 6 days long', presenter.formatted_trial_name
  end
end

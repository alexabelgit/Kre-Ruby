require 'test_helper'

module Stores
  class ExtendTrialTest < ActiveSupport::TestCase
    let(:new_trial_date) { 7.days.from_now.to_datetime }

    test 'changes store trial_ends date to new value' do
      store = create :store, trial_ends_at: 2.day.from_now

      described_class.run store: store, new_trial_date: new_trial_date
      assert_equal store.reload.trial_ends_at.to_i, new_trial_date.to_i
    end

    test 'reactivates the store when store has already been deactivated' do
      store = create :store, trial_ends_at: 2.day.from_now, deactivated_at: 2.days.from_now

      described_class.run store: store, new_trial_date: new_trial_date
      assert_nil store.reload.deactivated_at
    end
  end
end
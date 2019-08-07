module Stores
  class ExtendTrial < ApplicationCommand
    object :store

    date_time :new_trial_date

    def execute
      if new_trial_date < store.trial_ends_at
        errors.add(:store, 'new trial date should not be earlier than current trial date')
        return store
      end

      if new_trial_date < DateTime.current
        errors.add(:store, "new trial date should be in the future")
        return store
      end

      store.update trial_ends_at: new_trial_date
      store.update_settings :billing, trial_finished_email_sent: false,
                                      trial_ending_email_sent: false,
                                      grace_period_email_sent: false

      if store.deactivated_at
        compose(ResetDeactivation, store: store) if store.deactivated_at < new_trial_date
      end
      store
    end
  end
end
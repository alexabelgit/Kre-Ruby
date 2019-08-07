module Stores
  class StartBilling < ApplicationCommand
    object :store

    date_time :billing_start_date, default: DateTime.current
    boolean :reset_trial, default: false

    def execute
      unless store.can_be_billed?
        errors.add(:store, "can't start billing for not billable store")
        return store
      end

      params = { billing_started_at: billing_start_date }
      if reset_trial
        params[:trial_started_at] = DateTime.current
        params[:trial_ends_at] = DateTime.current + store.total_trial_duration
      end

      store.update params
    end
  end
end
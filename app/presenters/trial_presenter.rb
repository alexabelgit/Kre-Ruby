class TrialPresenter
  attr_reader :view, :presenter

  delegate :store, to: :presenter

  delegate :trial_ended?,
           :trial_ending?,
           :total_trial_duration,
           :days_left_on_trial,
           to: :store

  def initialize(billing_presenter)
    @presenter = billing_presenter
    @view      = billing_presenter.view
  end

  def subtitle
    if trial_ended?
      "Your free trial has expired, please pick a plan to continue using HelpfulCrowd"
    elsif trial_ending?
      "With the free trial, you have unlimited access to all of our features.
       Your trial is expiring in #{ view.pluralize days_left_on_trial, 'day' }"
    else
      "With the free trial, you have unlimited access to all of our features.
      Your trial will be active for #{ days_left_on_trial } more days"
    end
  end

  def progress
    trial_duration_in_days = total_trial_duration / 86400                # This is needed because total_trial_duration returns seconds not days
    trial_days_passed      = trial_duration_in_days - days_left_on_trial

    trial_days_passed.percent_of trial_duration_in_days
  end

  def color
    if trial_ended?
      'danger'
    elsif trial_ending?
      'warning'
    else
      'success'
    end
  end
end

Rails.configuration.billing = ActiveSupport::OrderedOptions.new
billing = Rails.configuration.billing
billing.launch_date = Date.parse(ENV['BILLING_LAUNCH_DATE'] || 'July 15 2018')

billing.overage_charges_launch_date = Date.parse(ENV['OVERAGE_CHARGES_LAUNCH_DATE'] || 'Sep 7 2018')
billing.default_trial_duration = ENV['DEFAULT_TRIAL_DURATION']&.days || 30.days
billing.extended_trial_duration = ENV['EXTENDED_TRIAL_DURATION']&.days || 90.days
billing.default_overages_limit = ENV['OVERAGES_LIMIT']&.to_i || 3000

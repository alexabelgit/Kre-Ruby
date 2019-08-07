class CheckForAbuseJob < ApplicationJob
  queue_as :default

  ### SIDEKIQED

  def perform(model_name, id)
    record = model_name.constantize.find(id)
    record.report_abuse
  end
end

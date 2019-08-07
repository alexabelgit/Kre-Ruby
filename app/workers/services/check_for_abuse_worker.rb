class CheckForAbuseWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default

  def perform(model_name, id)
    record = model_name.constantize.find(id)
    record.report_abuse
  end
end

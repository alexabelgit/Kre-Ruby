class ReindexChildJob < ApplicationJob
  queue_as :default

  ### SIDEKIQED

  def perform(model_name, model_ids)
    models = model_name.constantize.where(id: model_ids)
    models.reindex if models.present?
  end

end

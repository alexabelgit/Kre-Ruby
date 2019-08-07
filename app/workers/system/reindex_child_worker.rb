class ReindexChildWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: 3

  def perform(model_name, model_ids)
    model = model_name.constantize

    Array.wrap(model_ids).each do |id|
      model.search_index.reindex_queue.push(id)
    end
  end
end

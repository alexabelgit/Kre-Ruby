class StoreReindexer

  def initialize(store)
    @store = store
  end

  def reindex_all
    reindex 'Product', store.products
    reindex 'Review', store.reviews
    reindex 'ReviewRequest', store.review_requests
    reindex 'Question', store.questions
  end

  def reindex_product_groups
    reindex 'Review', store.reviews
    reindex 'Question', store.questions
  end

  private
  attr_reader :store

  def reindex(model, relation)
    return unless relation.any?
    ReindexChildWorker.perform_async(model, relation.pluck(:id))
  end
end

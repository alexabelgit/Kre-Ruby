class ProductGroupProduct < ApplicationRecord
  belongs_to :product_group, touch: true
  belongs_to :product, touch: true

  after_destroy_commit :reindex_children

  private

  def reindex_children
    reviews = Review.product_id(self.product_id)
    questions = Question.where(product: self.product)
    ReindexChildWorker.perform_async('Review', reviews.pluck(:id))     if reviews.any?
    ReindexChildWorker.perform_async('Question', questions.pluck(:id)) if questions.any?
  end

end

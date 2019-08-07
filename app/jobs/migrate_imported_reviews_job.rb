class MigrateImportedReviewsJob < ApplicationJob
  queue_as :default

  ### SIDEKIQED

  def perform(store_id)
    store = Store.find_by_id(store_id)
    return unless store.present?

    store.imported_reviews.where(marked_for_deletion: true).destroy_all
    Comment.skip_callback(:commit, :after, :reindex_children)
    Review.skip_callback(:commit, :after, :reindex_children)
    Searchkick.callbacks(false) do
      store.imported_reviews.where(marked_for_deletion: false).order(created_at: :asc).each do |imported_review|
        order         = Order.create(customer: imported_review.customer, order_date: DateTime.current)
        order_product = OrderProduct.create(order: order, product: imported_review.product)
        review        = Review.create(order_product: order_product,
                                      rating:        imported_review.rating,
                                      feedback:      imported_review.feedback,
                                      status:        imported_review.status,
                                      review_date:   imported_review.review_date,
                                      source:        'imported')
        review.verified_by_merchant! if imported_review.verified?
        review.update_attributes(publish_date: imported_review.review_date) if review.valid? && review.published?

        if review.valid? && imported_review.comment.present?
          Comment.create(commentable:  review,
                         body:         imported_review.comment,
                         user:         store.user,
                         display_name: store.settings(:agents).default_name)
        end

        imported_review.destroy
      end
    end
    Review.set_callback(:commit, :after, :reindex_children)
    Comment.set_callback(:commit, :after, :reindex_children)
    store.reindex_children

    store.settings(:background_workers).update_attributes(migrating_imported_reviews: false)
  end
end

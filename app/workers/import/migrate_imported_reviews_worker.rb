class MigrateImportedReviewsWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default

  def perform(store_id)
    store = Store.find_by_id(store_id)
    return unless store.present?

    store.imported_reviews.where(marked_for_deletion: true).destroy_all

    Searchkick.callbacks(false) do
      store.imported_reviews.where(marked_for_deletion: false).order(created_at: :asc).each do |imported_review|

        reviewable = imported_review.product.present? ? imported_review.product : store
        verification = imported_review.verified? ? :verified_by_merchant : :unverified

        outcome = ::Reviews::CreateReview.run(store:                 store,
                                              customer:              imported_review.customer,
                                              reviewables:           [reviewable],
                                              rating:                imported_review.rating,
                                              title:                 imported_review.title,
                                              feedback:              imported_review.feedback,
                                              status:                imported_review.status,
                                              verification:          verification,
                                              review_date:           imported_review.review_date.to_datetime,
                                              publish_date:          imported_review.review_date.to_datetime,
                                              source:                'imported',
                                              skip_reindex_children: true)

        if outcome.valid?
          review = outcome.result if outcome.valid?
          if imported_review.comment.present?
            Comment.create(commentable:           review,
                           body:                  imported_review.comment,
                           user:                  store.user,
                           display_name:          store.settings(:agents).default_name,
                           skip_reindex_children: true)
          end
          imported_review.media.each do |medium|
            medium.migrate_to_review!(review)
            imported_review.reload
          end
        end

        imported_review.destroy
      end
    end
    store.reindex_children

    store.settings(:background_workers).update_attributes(migrating_imported_reviews: false)
  end
end

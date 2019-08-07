class MigrateBulkRequestWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default

  def perform(store_id)
    store = Store.find_by_id(store_id)
    return unless store.present?

    store.imported_review_requests.where(marked_for_deletion: true).destroy_all

    Searchkick.callbacks(false) do
      store.imported_review_requests.where(marked_for_deletion: false).each do |imported_review_request|
        outcome = ::ReviewRequests::CreateReviewRequest.run customer:      imported_review_request.customer,
                                                            scheduled_for: imported_review_request.scheduled_for.to_datetime,
                                                            product_ids:   imported_review_request.products.pluck(:id),
                                                            business:      imported_review_request.products.any? ? nil : store
        imported_review_request.destroy if outcome.valid?
      end
    end
    store.reindex_children

    store.settings(:background_workers).update_attributes(migrating_imported_review_requests: false)
  end
end

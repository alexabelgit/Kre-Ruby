class BulkRequestWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default

  def perform(store_id, csv)
    store = Store.find_by id: store_id
    return if store.blank?

    Time.zone = store.time_zone

    importer = Importers::ReviewRequestsCsvImporter.new(store)
    unimported = importer.import csv

    upload_unimported_and_notify(store, csv, unimported) if unimported.any?

    store.reindex_children
    store.update_settings :background_workers,
                          review_requests_seed_running: false,
                          review_requests_seeded: true

    failed = csv.count == unimported.count
    broadcast_result store, failed: failed
  end

  private

  def upload_unimported_and_notify(store, csv, unimported_rows)
    uploader = FailedImportUploader.new(store)
    uploader.unimported_review_requests(unimported_rows)
    BackMailer.unimported_review_requests(store.user_id, csv.count, unimported_rows.count).deliver
  end

  def broadcast_result(store, failed:)
    broadcaster = OnboardingBroadcaster.new(store)
    message = failed ? 'failed' : 'ready'
    template = "back/imported_review_requests/#{message}"
    broadcaster.broadcast template, 'imported-review-requests'
  end
end

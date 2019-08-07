class ImportReviewsWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default

  def perform(store_id, csv, provider)
    store = Store.find_by id: store_id
    return if store.blank?

    Time.zone = store.time_zone

    importer = Importers::ReviewsCsvImporter.new(store)
    unimported_rows = importer.import csv, provider

    unless unimported_rows.empty?
      FailedImportUploader.new(store).unimported_reviews unimported_rows, provider: provider
      BackMailer.unimported_reviews(store.user_id, csv.count, unimported_rows.count).deliver
    end

    store.reindex_children
    store.update_settings :background_workers,
                          reviews_seed_running: false,
                          reviews_seeded: true

    broadcast_result store, failed: unimported_rows.count == csv.count
  end

  private

  def broadcast_result(store, failed:)
    broadcaster = OnboardingBroadcaster.new(store)
    message = failed ? 'failed' : 'ready'
    template = "back/imported_reviews/#{message}"
    broadcaster.broadcast template, 'imported-reviews'
  end
end

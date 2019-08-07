module Export
  class StoreReviewsExportWorker
    include Sidekiq::Worker
    sidekiq_options queue: :default

    def perform(download_id)
      download = Download.find_by_hashid download_id
      return if download.nil?

      download_entry = StoreReviewsExporter.new.export_reviews download
      BackMailer.reviews_export_ready(download_entry.store_id).deliver if download_entry.ready?
    end
  end
end

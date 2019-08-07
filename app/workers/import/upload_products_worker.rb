class UploadProductsWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default

  def perform(store_id, csv)
    store = Store.find_by id: store_id
    return if store.blank?

    Time.zone = store.time_zone
    importer = Importers::ProductCsvImporter.new(store)
    unimported = importer.import csv

    upload_unimported_and_notify(store, csv, unimported) if unimported.present?

    store.reindex_children
    store.update_settings :background_workers, uploading_products: false, products_uploaded: true

    failed = unimported.count == csv.count
    broadcast_result store, failed: failed
  end

  private

  def upload_unimported_and_notify(store, csv, unimported)
    FailedImportUploader.new(store).unimported_products unimported
    BackMailer.unimported_products(store.user_id, csv.count, unimported.count).deliver
  end

  def broadcast_result(store, failed:)
    broadcaster = OnboardingBroadcaster.new(store)
    message = failed ? 'failed' : 'ready'
    template = "back/products/upload/#{message}"
    broadcaster.broadcast template, 'imported-products'
  end
end

class FailedImportUploader
  attr_reader :store, :uploader

  def initialize(store)
    @store = store
    @uploader = AmazonS3Uploader.new
  end

  def unimported_reviews(rows, provider: :default)
    rows = serialize_reviews_csv rows, provider

    path = "#{store.hashid}/failed-reviews-import/unimported-reviews-#{current_datetime_as_number}"
    name = "Failed rows after reviews import on #{humane_current_date}"
    upload_csv name, 'unimported_reviews', path, rows
  end

  def unimported_products(rows)
    path = "#{store.hashid}/failed-products-import/unimported-products-#{current_datetime_as_number}"
    name = "Failed rows after products import on #{humane_current_date}"
    upload_csv name, 'unimported_products', path, rows
  end

  def unimported_questions(rows)
    path = "#{store.hashid}/failed-questions-import/unimported-questions-#{current_datetime_as_number}"
    name = "Failed rows after questions import on #{humane_current_date}"
    upload_csv name, 'unimported_questions', path, rows
  end

  def unimported_review_requests(rows)
    path = "#{store.hashid}/failed-review-requests-import/unimported-questions-#{current_datetime_as_number}"
    name = "Failed rows after review requests import on #{humane_current_date}"
    upload_csv name, 'unimported_review_requests', path, rows
  end

  private

  def current_datetime_as_number
    DateTime.current.to_s(:number)
  end

  def humane_current_date
    I18n.l(DateTime.current, format: :long)
  end

  def upload_csv(name, filetype, path, rows)
    download_entry = Download.create store: store, status: :processing, filetype: filetype, name: name, path: path

    csv = build_csv rows
    result = uploader.upload_text path, csv
    params = {}
    if result.status == :success
      params[:url] = result.url
      params[:status] = :ready
    else
      params[:status] = :error
    end
    download_entry.update params
    download_entry
  end

  def build_csv(rows)
    headers = rows.first.keys
    CSV.generate do |csv|
      csv << headers
      rows.reverse_each { |r| csv << r.values }
    end
  end

  def serialize_reviews_csv(rows, provider)
    return YotpoReviewsParser.parse_to_yotpo(rows) if provider == :yotpo
    rows
  end
end
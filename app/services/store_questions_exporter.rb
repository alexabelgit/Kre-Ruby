class StoreQuestionsExporter
    attr_reader :uploader
    include ApplicationHelper
  
    def initialize
      @uploader = AmazonS3Uploader.new
    end
  
    def export_questions(download_entry)
      download_entry.update status: :processing
      store = download_entry.store
  
      csv = store.questions.to_csv
      path = filepath(store)
      result = uploader.upload_text path, csv
  
      params = { name: readable_name, path: path }
      if result.status == :success
        params[:url] = result.url
        params[:status] = :ready
      else
        params[:status] = :error
      end
      download_entry.update params
      download_entry
    end
  
    private
  
    def readable_name
      time = I18n.l(DateTime.current, format: :long)
      "Questions export from #{time}"
    end
  
    def filepath(store)
      "#{store.hashid}/questions-#{DateTime.current.to_s(:number)}.csv"
    end
  end
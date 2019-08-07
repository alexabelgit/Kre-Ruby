module Export
    class StoreQuestionsExportWorker
      include Sidekiq::Worker
      sidekiq_options queue: :default
  
      def perform(download_id)
        download = Download.find_by_hashid download_id
        return if download.nil?
  
        download_entry = StoreQuestionsExporter.new.export_questions download
        BackMailer.questions_export_ready(download_entry.store_id).deliver if download_entry.ready?
      end
    end
  end
  
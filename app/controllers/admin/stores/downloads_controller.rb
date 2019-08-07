module Admin
  module Stores
    class DownloadsController < StoresController
      before_action :set_store

      def index
        add_breadcrumb @store.name, admin_store_path(@store)
        add_breadcrumb 'Downloads', admin_store_downloads_path(@store)

        @downloads = @store.downloads.ordered.paginate(page: params[:page], per_page: 20)
      end

      def export_reviews
        schedule_reviews_export @store
        redirect_to admin_store_downloads_path(@store)
      end

      def export_questions
        schedule_questions_export @store
        redirect_to admin_store_downloads_path(@store)
      end

      def destroy
        download = @store.downloads.find_by id: params[:id]
        successful =  download.destroy

        flash[:error] = 'Failed to delete store download' unless successful
        redirect_to admin_store_downloads_path(@store)
      end

      private

      def schedule_reviews_export(store)
        pending_upload = Download.create status: :pending, filetype: 'reviews_export', store: store
        Export::StoreReviewsExportWorker.perform_async pending_upload.to_param
      end

      def schedule_questions_export(store)
        pending_upload = Download.create status: :pending, filetype: 'questions_export', store: store
        Export::StoreQuestionsExportWorker.perform_async pending_upload.to_param
      end

      def set_store
        @store = Store.find_by_hashid params[:store_id]
      end
    end
  end
end
class Back::ReviewRequests::BulkRequestController < BackController
  def new
  end

  def create
    if bulk_request_params[:file].present?
      csv = Array.csv_to_array(bulk_request_params[:file])
      if csv
        if csv.empty?
          flash[:error] = 'The file is empty'
        else
          if Upload.check_columns(csv.first.keys, 'review_request', nil)
            current_store.settings(:background_workers).update_attributes(review_requests_seed_running: true)
            BulkRequestWorker.perform_async(current_store.id, csv)
          else
            flash[:error] = 'We could not process your CSV file, please make sure its columns match the provided template'
          end
        end
      else
        flash[:error] = 'Invalid csv format'
      end
    end
    redirect_to back_bulk_request_index_path
  end

  private

  def bulk_request_params
    params.require(:bulk_request).permit(:file)
  end
end

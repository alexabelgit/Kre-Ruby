class Back::ImportedReviewRequestsController < BackController

  def index
    @imported_review_requests = current_store.imported_review_requests.latest.paginate(per_page: 20, page: params[:page])
  end

  def update
    @imported_review_request = current_store.imported_review_requests.find_by_hashid(params[:id])
    @imported_review_request.update_attributes(imported_review_request_params)

    respond_to do |format|
      format.html { redirect_to back_imported_review_requests_url }
      format.js
    end
  end

  def proceed
    current_store.settings(:background_workers).update_attributes(migrating_imported_review_requests: true)
    if params[:clear_all]
      current_store.imported_review_requests.update_all(marked_for_deletion: true)
    else
      flash[:success] = 'Review requests successfully generated. New items will show up in a few moments.'
    end
    MigrateBulkRequestWorker.perform_async(current_store.id)

    respond_to do |format|
      format.html { redirect_to (params[:clear_all].present? ? back_imported_review_requests_url : back_review_requests_url) }
      format.js
    end
  end

  private

  def imported_review_request_params
    params.require(:imported_review_request).permit(:marked_for_deletion)
  end
end

class Back::ImportedReviewsController < BackController

  def index
    @imported_reviews = current_store.imported_reviews.latest.paginate(per_page: 20, page: params[:page])
  end

  def update
    @imported_review = current_store.imported_reviews.find_by_hashid(params[:id])
    @imported_review.update_attributes(imported_review_params)

    respond_to do |format|
      format.html { redirect_to back_imported_reviews_url }
      format.js
    end
  end

  def proceed

    current_store.settings(:background_workers).update_attributes(migrating_imported_reviews: true)
    if params[:clear_all]
      current_store.imported_reviews.update_all(marked_for_deletion: true)
    else
      flash[:success] = 'Reviews successfully imported. New items will show up in a few moments.'
    end
    MigrateImportedReviewsWorker.perform_async(current_store.id)

    respond_to do |format|
      format.html { redirect_to (params[:clear_all].present? ? back_imported_reviews_url : back_reviews_url) }
      format.js
    end
  end

  private

  def imported_review_params
    params.require(:imported_review).permit(:marked_for_deletion)
  end

end

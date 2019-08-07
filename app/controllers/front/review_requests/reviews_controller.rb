class Front::ReviewRequests::ReviewsController < FrontController

  def new
    @review_request   = @store.review_requests.find_by_hashid(params[:review_request_id])
    @transaction_item = get_transaction_item(@review_request)
    @rating           = params[:rating]
  end

  def create
    @header          = params[:header].present? && params[:header].to_b

    transaction_item = @store.customer_transaction_items.find_by_id_or_hashid(review_params[:transaction_item_id]) #TODO ~~ why not only by hashid?
    outcome          = ::Reviews::CreateReview.run review_params.except(:transaction_item_id).merge(transaction_item: transaction_item, store: @store)
    @review          = outcome.result

    respond_to do |format|
      @success = outcome.valid?

      if @success
        BackMailer.pending(@review).deliver

        format.html { redirect_to thank_you_front_review_path(@review.store.hashid, @review) }
        format.js
      else
        # TODO: it gets to this point but falsely returns true for @review.valid? so no errors are shown on page
        logger.info "valid: #{@review.valid?} | Should be false"
        format.html { render :edit }
        format.js
      end
    end
  end

  private

  def review_params
    if @store.media_reviews_enabled?
      params.require(:review).permit(:rating, :feedback, :transaction_item_id, media_attributes: [:cloudinary_public_id, :media_type])
    else
      params.require(:review).permit(:rating, :feedback, :transaction_item_id)
    end
  end

  def get_transaction_item(review_request)
    @store.customer_transaction_items.find_by_hashid(params[:transaction_item_id]) ||
    review_request.transaction_items.without_reviews.first ||
    review_request.transaction_items.first
  end
end

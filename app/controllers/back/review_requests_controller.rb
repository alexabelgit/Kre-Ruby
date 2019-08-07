class Back::ReviewRequestsController < BackController
  before_action :set_review_request, only: [:update, :cancel, :send_now, :events]

  def index
    @review_requests =
      ReviewRequest.includes(:order, :emails, customer: [:store], transaction_items: [:customer, :review, :reviewable, :product])
                   .filtered(current_store: current_store,
                           term:          search_params[:term],
                           filter_params: {},
                           sort:          :latest,
                           page:          params[:page],
                           per_page:      10)
  end

  def new
    @review_request = ReviewRequest.new(scheduled_for: current_store.get_scheduled_for)
  end

  def create
    scheduled_for = DateTime.civil_with_timezone(review_request_params['scheduled_for(1i)'].to_i,
                                                 review_request_params['scheduled_for(2i)'].to_i,
                                                 review_request_params['scheduled_for(3i)'].to_i,
                                                 review_request_params['scheduled_for(4i)'].to_i,
                                                 review_request_params['scheduled_for(5i)'].to_i)

    unless scheduled_for
      respond_to do |format|
        @review_request = ReviewRequest.new
        @review_request.errors.add(:scheduled_for, 'Invalid date')
        format.html { render :new }
      end
      return
    end

    outcome = ::ReviewRequests::CreateReviewRequest.run product_ids:    [product_params[:id]],
                                                        customer_email: customer_params[:email],
                                                        customer_name:  customer_params[:name],
                                                        scheduled_for:  @store.active? ? scheduled_for : nil,
                                                        status:         @store.active? ? :scheduled : :on_hold,
                                                        store:          current_store
    @review_request = outcome.result

    respond_to do |format|
      if outcome.valid?
        if @review_request.suppressed?
          flash[:warning] = "#{ @review_request.customer.email } is in the suppression list. This request will not be sent."
        elsif scheduled_for > DateTime.current
          flash[:info] = "Review request will be sent in #{ helpers.distance_of_time_in_words_to_now(scheduled_for) }."
        else
          flash[:info] = 'Review request will be sent shortly.'
        end

        format.html { redirect_to back_review_requests_path }
        format.json { render :show, status: :created, location: @review_request }
      else
        format.html { render :new }
        format.json { render json: @review_request.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @review_request.update(review_request_params)
        format.html { redirect_to back_review_requests_path, notice: 'Review request was successfully updated.' }
        format.json { render :show, status: :ok, location: @review_request }
      else
        format.html { render :edit }
        format.json { render json: @review_request.errors, status: :unprocessable_entity }
      end
    end
  end

  def cancel
    @review_request.cancel!
    flash.now[:warning] = 'Review request cancelled.'
    respond_to do |format|
      # TODO why redirect?
      format.html { redirect_to back_review_requests_path, notice: 'Review request was successfully updated.' }
      format.js
    end
  end

  def send_now
    if !@review_request.send_restricted?
      @review_request.update_columns(scheduled_for: DateTime.current)
      if @review_request.proceed
        flash.now[:info] = 'Review request will be sent shortly.'
      else
        flash.now[:warning] = 'Review request can not be sent.'
      end
    elsif @review_request.suppressed?
      flash.now[:error] = "Email was not sent, #{@review_request.customer.email} is in the suppression list."
    end
    respond_to do |format|
      # TODO why redirect?
      format.html { redirect_to back_review_requests_path, notice: 'Review request was successfully updated.' }
      format.js
    end
  end

  def process_on_hold
    current_store.settings(:background_workers).update_attributes(proceed_on_hold_review_requests_running: true)
    ProceedOnHoldReviewRequestsWorker.perform_async(current_store.id)
    redirect_to back_review_requests_path
  end

  private

  def set_review_request
    @review_request = current_store.review_requests.find_by_id_or_hashid(params[:id]) #TODO ~~ why not only by hashid?
  end

  def review_request_params
    params.require(:review_request).permit(:scheduled_for, :product_id)
  end

  def customer_params
    params.require(:customer).permit(:email, :name)
  end

  def product_params
    params.require(:product).permit(:id)
  end

  def search_params
    params.permit(:term)
  end

end

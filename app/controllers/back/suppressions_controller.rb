class Back::SuppressionsController < BackController
  before_action :set_suppression, only: [ :destroy ]

  def index
    @suppressions = current_store.suppressions.latest.paginate(page: params[:page], per_page: 10)
  end

  def new
    @suppression = Suppression.new
  end

  def create
    @suppression = Suppression.new(suppression_params)

    @suppression.store  = current_store
    @suppression.source = :by_merchant

    respond_to do |format|
      if @suppression.save
        flash[:success] = "#{ @suppression.email } successfully suppressed. HelpfulCrowd will no longer email them on your behalf"
        format.html { redirect_to back_suppressions_path }
        format.json { render :show, status: :created, location: @suppression }
      else
        format.html { render :new }
        format.json { render json: @suppression.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    if @suppression.by_merchant?
      @suppression.destroy

      flash[:info] = "No longer suppressing emails addressed to #{ @suppression.email }"

      respond_to do |format|
        format.html { redirect_to back_suppressions_path }
        format.json { head :no_content }
      end
    elsif @suppression.by_customer?
      flash[:error] = "Not allowed: #{ @suppression.email } is suppressed due to customer unsubscribe"
      redirect_to back_suppressions_path
    end
  end

  private

  def set_suppression
    @suppression = current_store.suppressions.find_by_hashid(params[:id])
  end

  def suppression_params
    params.require(:suppression).permit(:email)
  end
end

class Back::Reviews::MediaController < BackController

  before_action :set_medium, only: [:update]

  def update
    @medium.update_attributes(status: params[:status]) if params[:status].present?
    respond_to do |format|
      format.html { redirect_to back_reviews_path }
      format.js
    end
  end

  private

  def set_medium
    @medium = current_store.reviews.find_by_hashid(params[:review_id]).media.find_by_hashid(params[:id])
  end

end
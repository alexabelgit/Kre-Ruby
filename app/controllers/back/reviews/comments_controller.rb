class Back::Reviews::CommentsController < Back::CommentsController

  before_action :set_commentable, only: [:create]

  private

  def set_commentable
    @commentable = current_store.reviews.find_by_hashid(params[:review_id])
  end
  
end

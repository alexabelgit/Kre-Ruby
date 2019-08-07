class Back::Questions::CommentsController < Back::CommentsController

  before_action :set_commentable, only: [:create]

  private

  def set_commentable
    @commentable = current_store.questions.find_by_hashid(params[:question_id])
  end

end
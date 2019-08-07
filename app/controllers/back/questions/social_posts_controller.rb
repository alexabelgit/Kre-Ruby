class Back::Questions::SocialPostsController < Back::SocialPostsController

  before_action :set_postable, only: [:create]

  private

  def set_postable
    @postable = current_store.questions.find_by_hashid(params[:question_id])
  end
end
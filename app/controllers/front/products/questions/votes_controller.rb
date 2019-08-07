class Front::Products::Questions::VotesController < Front::VotesController

  before_action :set_votable, only: [ :create ]

  private

  def set_votable
    @votable = @store.questions.published.find_by_hashid(params[:question_id])
  end
end

class Front::Products::Reviews::VotesController < Front::VotesController

  before_action :set_votable, only: [ :create ]

  private

  def set_votable
    @votable = Review.published.find_by_hashid(params[:review_id])
  end
end

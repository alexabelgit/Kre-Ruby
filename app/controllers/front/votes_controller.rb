class Front::VotesController < FrontController

  skip_before_action :verify_authenticity_token, only: [ :create ]

  def create
    if session.validate_record?(@votable, scope: :vote)
      @vote = Vote.create(votable: @votable)

      session.store_record(@votable, scope: :vote)
    end

    @vote = @votable.votes.first

    respond_to do |format|
      format.html
      format.js
    end
  end

end

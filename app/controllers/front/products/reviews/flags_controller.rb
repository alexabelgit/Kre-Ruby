class Front::Products::Reviews::FlagsController < Front::FlagsController

  before_action :set_flaggable, only: [ :create ]

  private

  def set_flaggable
    @flaggable = Review.published.find_by_hashid(params[:review_id])
  end
end

class Back::Reviews::SocialPostsController < Back::SocialPostsController
  before_action :set_postable, only: [:create]

  private

  def set_postable
    @postable = current_store.reviews.find_by_hashid(params[:review_id])
  end
end
class Admin::ReviewsController < AdminController
  before_action :set_review, only: [ :show ]

  add_breadcrumb "Admin",   :admin_root_path
  add_breadcrumb "Reviews", :admin_reviews_path

  def index
    @reviews = Review.includes(:media, :social_posts, :customer, :products, :businesses)
                     .order(created_at: :desc)
                     .paginate(page: params[:page], per_page: 100)
  end

  def show
    add_breadcrumb @review.hashid, admin_review_path(@review)
  end

  private

  def set_review
    @review = Review.find_by_hashid(params[:id])
  end
end

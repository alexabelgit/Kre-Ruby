class Back::ReviewsController < BackController

  before_action :set_review, only: [:show, :update]

  def index
    @reviews = Review.includes(:comment, :social_posts, :flags, :products, customer: [:store])
                     .includes(:media)
                     .filtered(current_store: current_store,
                             term:          search_params[:term],
                             filter_params: filter_params,
                             sort:          :by_created_at,
                             page:          params[:page],
                             per_page:      5)
  end

  def show

  end

  def update
    outcome = ::Reviews::UpdateReview.run review_params.merge(review: @review)

    if outcome.valid?
      @review = outcome.result
      if review_params[:with_incentive].present?
        if @review.with_incentive?
          flash.now[:notice] = 'Review was marked as incentivised', :fade
        else
          flash.now[:notice] = 'Incentivised flag was removed from review', :fade
        end
      elsif review_params[:status].present?
        if @review.archived?
          social_posts_present = true if @review.social_posts.any?
          @review.social_posts.destroy_all

          flash.now[:notice] = (social_posts_present ?
                               'Review was archived and corresponding social posts were unpublished.' :
                               'Review was archived.'), :fade
        elsif @review.published?
          flash.now[:success] = 'Review was published.', :fade
        end
      end

      respond_to do |format|
        if params.has_key?(:app)
          case params[:app]
          when 'ecwid'
            format.html { redirect_to integrations_ecwid_path }
            format.js   { render "integrations/ecwid/reviews/update" }
          when 'shopify'
            format.html { redirect_to integrations_shopify_path }
            format.js   { render "integrations/shopify/reviews/update" }
          end
        else
          format.html { redirect_to back_reviews_path }
          format.js
        end
      end
    else
      respond_to do |format|
        if params.has_key?(:app)
          case params[:app]
          when 'ecwid'
            format.html { render "integrations/ecwid/dashboard/index" }
            format.js   # TODO this should be replaced with appropriate file in integrations/ecwid..
          when 'shopify'
            format.html { render "integrations/shopify/dashboard/index" }
            format.js   # TODO this should be replaced with appropriate file in integrations/shopify..
          end
        else
          format.html { render :show }
          format.js
        end
      end
    end
  end

  def publish_all_pending
    current_store.reviews.pending.each do |review|
      review.update_attributes(status: :published)
    end

    flash[:success] = 'Pending reviews published'

    if request.referrer.present?
      redirect_to(request.referrer)
    else
      redirect_to(back_reviews_path)
    end
  end

  private

  def set_review
    @review = current_store.reviews.find_by_hashid(params[:id])
  end

  def review_params
    params.require(:review).permit(:status, :with_incentive)
  end

  def filter_params
    params.permit(:status, :rating, :product_id, :product_group_ids)
  end

  def search_params
    params.permit(:term)
  end

end

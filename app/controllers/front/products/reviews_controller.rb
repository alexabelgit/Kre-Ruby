class Front::Products::ReviewsController < FrontController
  before_action :set_product, only: [:index, :show, :new, :create]

  def index
    if filter_params.empty? && search_params[:term].nil? && (sort_params[:sort].nil? || sort_params[:sort] == 'latest')
      @reviews = @product.reviews.published.latest.paginate(page: params[:page], per_page: @store.items_per_page)
      @reviews_with_media = @product.reviews.published.latest.with_media

      @reviews.define_filterable_methods!(
        search_term:  nil,
        filter_value: { status: :published, product_group_ids: [@product.id] },
        sort_mode:    :latest
      )
    else
      filter = filter_params.merge!({ status: :published, product_group_ids: [@product.id] })
      sort   = sort_params[:sort] ||= :latest

      @reviews =
        Review.filtered(
          current_store: @product.store,
          term:          search_params[:term],
          filter_params: filter,
          sort:          sort,
          page:          params[:page],
          per_page:      @store.items_per_page
        )
      @reviews_with_media =
        Review.filtered(
          current_store: @product.store,
          term:          search_params[:term],
          filter_params: filter,
          sort:          sort
        )
    end
    respond_to do |format|
      format.html { redirect_to front_product_url(@product.store, @product) }
      format.js
    end
  end

  def show
    @review = @product.reviews.published.find_by_hashid(params[:id])

    if @review.present?
      title       = "#{ @review.rating.to_stars } #{ @review.product.name }"
      description = "#{ @review.display_name } - #{ @review.feedback }"
      image       = @review.media_collage? ? @review.media_collage : @review.product.featured_image_url

      set_meta_tags title:         title,
                    description:   description,

                    fb: {
                      app_id:      ENV['FACEBOOK_APP_ID']
                    },

                    og: {
                      title:       title,
                      type:        'website',
                      image:       image,
                      url:         front_product_review_url(@review.store.hashid, @product.hashid, @review),
                      description: description
                    },

                    twitter: {
                      card:        'summary_large_image',
                      site:        '@HelpfulCrowdApp',
                      title:       title,
                      description: description,
                      image:       image
                    }
    end

    if params[:redirect]
      redirect_to @product.url unless browser.bot?
    end
    respond_to do |format|
      format.html
      format.js
    end
  end

  def new
    redirect_to @product.url unless @store.easy_reviews?
  end

  def create

    if @store.easy_reviews?
      customer_email, customer_name = customer_params[:email], customer_params[:name]
    elsif @guest_customer.present?
      customer_email, customer_name = @guest_customer.email, @guest_customer.name
    else
      customer_email, customer_name = nil, nil
    end
    outcome = ::Reviews::CreateReview.run review_params.merge(customer_email: customer_email,
                                                              customer_name:  customer_name,
                                                              source:         :voluntary,
                                                              reviewables:    [@product],
                                                              store:          @store)
    @review = outcome.result

    respond_to do |format|
      @success =
        (!@store.recaptcha_enabled? || verify_recaptcha(model: @review)) &&
        outcome.valid?

      if @success
        BackMailer.pending(@review).deliver

        format.html { redirect_to thank_you_front_review_path(@review.store.hashid, @review) }
        format.js
      else
        format.html { render :edit }
        format.js
      end
    end
  end

  private

  def review_params
    if @store.media_reviews_enabled?
      params.require(:review).permit(:rating, :feedback, media_attributes: [:cloudinary_public_id, :media_type])
    else
      params.require(:review).permit(:rating, :feedback)
    end
  end

  def hostname
    Rails.env.production? ? URI.parse(@store.url).host : 'localhost'
  end

  def customer_params
    params.require(:customer).permit(:email, :name) if @store.easy_reviews?
  end

  def set_product
    return head(404) unless @store
    @product = @store.products.find_by_id_from_provider_or_hashid(params[:product_id])
  end

  def filter_params
    params.permit(:rating)
  end

  def sort_params
    params.permit(:sort)
  end

  def search_params
    params.permit(:term)
  end
end

class Front::WidgetsController < FrontController
  after_action :allow_facebook_iframe, only: :reviews_facebook_tab

  layout 'front/widget'

  def sidebar
    @reviews   = @store.recent_reviews
    @questions = @store.recent_questions

    respond_to do |format|
      format.js
    end
  end

  def review_journal
    @reviews = @store.recent_reviews

    respond_to do |format|
      format.js
    end
  end

  def review_slider
    @reviews = @store.recent_reviews.limit(10)

    respond_to do |format|
      format.html
      format.js
    end
  end

  def reviews_facebook_tab
    @reviews = @store.recent_reviews(page: params[:page])

    render layout: 'integrations/facebook'
  end

  private

  def allow_facebook_iframe
    # TODO should not this allow only facebook domain instead of ALLOWALL?
    response.headers['X-Frame-Options'] = 'ALLOWALL'
  end
end

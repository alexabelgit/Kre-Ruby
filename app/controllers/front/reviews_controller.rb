class Front::ReviewsController < FrontController

  def index
    @reviews        = @store.recent_reviews(page: params[:page])

    @load_more      = params[:load_more].present? && params[:load_more].to_b
    @container_uuid = params[:container_uuid]

    title       = 'Reviews'
    description = "List of all reviews available at #{ @store.name }"
    image       = @store.logo

    set_meta_tags title:         title,
                  description:   description,

                  fb: {
                    app_id:      ENV['FACEBOOK_APP_ID']
                  },

                  og: {
                    title:       title,
                    type:        'website',
                    image:       image,
                    url:         front_reviews_url(@store.hashid),
                    description: description
                  },

                  twitter: {
                    card:        'summary',
                    site:        '@HelpfulCrowdApp',
                    title:       title,
                    description: description,
                    image:       image
                  }

    respond_to do |format|
      format.html
      format.js
    end
  end

end

class Front::ProductsController < FrontController

  before_action :set_product,          only: [ :show ]
  before_action :return_if_suppressed, only: [ :show ]

  def show
    title       = "#{ @product.rating.to_stars } #{ @product.name }"
    description = "Reviews and Q&A for #{ @product.name }"
    image       =  @product.featured_image.url

    set_meta_tags title:         title,
                  description:   description,

                  fb: {
                    app_id:      ENV['FACEBOOK_APP_ID']
                  },

                  og: {
                    title:       title,
                    type:        'website',
                    image:       @product.featured_image.url,
                    url:         front_product_url(@product.store.hashid, @product.hashid),
                    description: description
                  },

                  twitter: {
                    card:        'summary',
                    site:        '@HelpfulCrowdApp',
                    title:       title,
                    description: description,
                    image:       image
                  }

    # TODO Try pure postgres
    # @reviews =   Review.filtered(current_store: @product.store,
    #                           term:           nil,
    #                           filter_params:  { status: :published, product_group_ids: [@product.id] },
    #                           sort:           :latest,
    #                           page:           1,
    #                           per_page:       12)
    # TODO Cleaner Way
    @reviews = @product.recent_reviews(page: 1, per_page: @store.items_per_page)
    @reviews_with_media = @product.recent_reviews.with_media


    @reviews.define_filterable_methods!(
      search_term:  nil,
      filter_value: { status: :published, product_group_ids: [@product.id] },
      sort_mode:    :latest
    )

    # @questions = Question.filtered(current_store: @product.store,
    #                              term:          nil,
    #                              filter_params: { status: :published, product_group_ids: [@product.id] },
    #                              sort:          :latest,
    #                              page:          1,
    #                              per_page:      12)
    # TODO Cleaner Way
    @questions = @product.recent_questions(page: 1, per_page: @store.items_per_page)

    @questions.define_filterable_methods!(
      search_term:  nil,
      filter_value: { status: :published, product_group_ids: [@product.id] },
      sort_mode:    :latest
    )

    respond_to do |format|
      format.html
    end
  end

  private

  def set_product
    @product = @store.products.unsuppressed.find_by_id_from_provider_or_hashid params[:id]
  end

  def return_if_suppressed
    not_found unless @product
  end
end

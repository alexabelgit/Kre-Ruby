class Front::Widgets::ProductsController < Front::WidgetsController
  before_action :set_product
  before_action :return_if_suppressed
  before_action :set_title

  def tabs
    @reviews = @product.recent_reviews(page: 1, per_page: @store.items_per_page)
    @reviews_with_media = @product.reviews.published.latest.with_media

    @reviews.define_filterable_methods!(
      search_term:  nil,
      filter_value: { status: :published, product_group_ids: [@product.id] },
      sort_mode:    :latest
    )

    @questions = @product.recent_questions(page: 1, per_page: @store.items_per_page)

    @questions.define_filterable_methods!(
      search_term:   nil,
      filter_value: { status: :published, product_group_ids: [@product.id] },
      sort_mode:    :latest
    )

    respond_to do |format|
      format.html
      format.js
    end
  end

  def rating
    respond_to do |format|
      format.html
      format.js
    end
  end

  def summary
    respond_to do |format|
      format.html
      format.js
    end
  end

  def ld_json
    respond_to do |format|
      format.js
    end
  end

  private

  def set_product
    return head(404) unless @store
    @product = @store.products.find_by_id_from_provider_or_hashid(params[:product_id])
  end

  def return_if_suppressed
    render(body: nil) if @product.nil? || @product.suppressed?
  end

  def set_title
    title = "#{ @product.rating.to_stars } #{ @product.name }"
    set_meta_tags title: title
  end
end

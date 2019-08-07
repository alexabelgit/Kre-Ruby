class Back::DashboardController < BackController

  def index
    @presenter = Back::DashboardPresenter.new(current_store, view_context)
  end

  def product_stats
    if params[:product_id].present?
      @product = current_store.products.find_by_id_or_hashid(params[:product_id])
      @reviews = @product.reviews.published
    else
      @reviews = current_store.reviews.published
    end

    respond_to do |format|
      format.js
    end
  end

end

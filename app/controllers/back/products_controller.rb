class Back::ProductsController < BackController
  before_action :set_product, only: [:show, :edit, :update, :destroy]
  before_action :require_managed_products, only: [:new, :create, :destroy]

  def index
    sort = sort_params.presence || { a24z: :asc }

    @products = Product.filtered current_store:       current_store,
                                 term:                search_params[:term],
                                 filter_params:       filter_params,
                                 filter_gte_params:   filter_gte_params,
                                 sort:                sort,
                                 page:                params[:page],
                                 per_page:            10

    @page = params[:page]
    @products_any = current_store.products.any?
  end

  def show
  end

  def new
    @product = current_store.products.new
  end

  def edit
  end

  def create
    inputs = params.fetch(:product, {}).merge(store: current_store)
    outcome = ::Products::CreateProduct.run inputs
    @product = outcome.result

    respond_to do |format|
      if outcome.valid?
        format.html do
          flash[:success] = 'Product created', :fade
          redirect_to back_product_path(@product)
        end

        format.json { render :show, status: :created, location: @product }
      else
        format.html { render :new }
        format.json { render json: outcome.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    inputs = params.fetch(:product, {}).merge(product: @product, store: current_store)
    outcome = ::Products::UpdateProduct.run inputs

    respond_to do |format|
      if outcome.valid?
        format.html do
          flash[:success] = 'Product updated', :fade
          redirect_to back_products_path(outcome.result, page: params[:page])
        end
        format.json { render :show, status: :ok, location: outcome.result }
      else
        format.html do
          flash[:error] = outcome.errors.full_messages
          render :edit
        end
        format.json { render json: outcome.errors, status: :unprocessable_entity }
      end
    end
  end

  def sync
    ImportProductsWorker.perform_async(current_store.id)
    respond_to do |format|
      format.html { redirect_to back_products_path, notice: 'Products are now syncing. Updates will show up in the catalog soon' }
    end
  end

  def destroy
    @product.destroy

    respond_to do |format|
      flash[:info] = 'Product deleted', :fade
      format.html { redirect_to back_products_path }
      format.json { head :no_content }
    end
  end

  private

  def require_managed_products
    unless current_store.manages_products?
      flash[:error] = "Your products are synced with your e-commerce platform and you cannot add or delete them manually"
      redirect_to back_products_path
    end
  end

  def set_product
    @product = current_store.products.find_by_hashid(params[:id])
  end

  def product_params
    if current_store.manages_products?
      params.require(:product).permit(:name, :id_from_provider, :url, :suppressed)
    else
      params.require(:product).permit(:suppressed)
    end
  end

  def product_image_params
    params.require(:product).permit(:featured_image, :featured_image_cache) if current_store.manages_products?
  end

  def sort_params
    params.permit(:a24z, :by_rating, :reviews_count, :questions_count)
  end

  def search_params
    params.permit(:term)
  end

  def filter_params
    params.permit(:status, :product_id, :product_group_ids)
  end

  def filter_gte_params
    params.permit(:rating)
  end

end

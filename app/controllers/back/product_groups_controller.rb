class Back::ProductGroupsController < BackController

  before_action :set_product_group,  only:   [ :show, :edit, :update, :destroy ]
  before_action :set_products,       only:   [ :new, :create, :edit, :update ]

  def index
    @product_groups = current_store.product_groups.a24z.paginate(page: params[:page], per_page: 10)
  end

  def show
  end

  def new
    @product_group = ProductGroup.new
  end

  def edit
  end

  def create
    @product_group = current_store.product_groups.new(product_group_params)

    respond_to do |format|
      if @product_group.save
        format.html do
          flash[:success] = 'Product group created', :fade
          redirect_to back_product_group_path(@product_group)
        end

        format.json { render :show, status: :created, location: @product_group }
      else
        format.html { render :new }
        format.json { render json: @product_group.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @product_group.update(product_group_params)
        flash[:success] = 'Product group updated', :fade
        format.html { redirect_to back_product_group_path(@product_group) }
        format.json { render :show, status: :ok, location: @product_group }
      else
        format.html { render :edit }
        format.json { render json: @product_group.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @product_group.destroy

    respond_to do |format|
      flash[:success] = 'Product group removed', :fade
      format.html { redirect_to back_product_groups_path }
      format.json { head :no_content }
    end
  end

  private

  def set_product_group
    @product_group = current_store.product_groups.find_by_hashid(params[:id])
  end

  def set_products
    @products = current_store.products
  end

  def product_group_params
    params.require(:product_group).permit(:name, product_ids: [])
  end
end

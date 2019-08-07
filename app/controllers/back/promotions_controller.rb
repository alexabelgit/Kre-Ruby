class Back::PromotionsController < BackController
  before_action :check_if_promotions_is_enabled
  before_action :set_promotion, only: [:show, :edit, :update, :destroy]

  def index
    @promotions = current_store.promotions.latest.paginate(page: params[:page], per_page: 10)
  end

  def show
  end

  def new
    @promotion = current_store.promotions.new(starts_at: DateTime.current, ends_at: nil)
  end

  def edit
  end

  def create
    @promotion = current_store.promotions.new(promotion_params)

    respond_to do |format|
      if params[:discount_coupon].present?
        discount_coupon = current_store.discount_coupons.visible.find_by_hashid(discount_coupon_params[:id])
        @promotion.promotion_discount_coupons << PromotionDiscountCoupon.new(discount_coupon: discount_coupon)
      end

      if @promotion.save
        flash[:success] = 'Promotion created', :fade
        format.html { redirect_to back_promotions_path }
      else
        format.html { render :new }
      end
    end
  end

  def update
    outcome = ::Promotions::UpdatePromotion.run promotion_params.merge(promotion: @promotion, discount_coupon_id: discount_coupon_params[:id], store: current_store)

    @promotion = outcome.result

    hide_check_announcement

    respond_to do |format|
      if outcome.valid?
        format.html { redirect_to back_promotions_path }
      else
        format.html { render :edit }
      end
    end
  end

  def destroy
    @promotion.destroy
    @promotion.remove_from_all_templates
    respond_to do |format|
      flash[:info] = 'Promotion deleted', :fade
      format.html { redirect_to back_promotions_path }
    end
  end

  def hide_check_announcement
    @store.update_settings(:promotions, check_required: false)
  end

  private

  def check_if_promotions_is_enabled
    redirect_to back_dashboard_index_path unless @store.promotions_enabled?
  end

  def set_promotion
    @promotion = current_store.promotions.find(params[:id])
  end

  def promotion_params
    params.require(:promotion).permit(:name, :template, :starts_at, :ends_at, :incentive)
  end

  def discount_coupon_params
    params.fetch(:discount_coupon, {}).permit(:id)
  end
end

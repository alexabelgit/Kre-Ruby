class Back::DiscountCouponsController < BackController
  before_action :check_if_promotions_is_enabled
  before_action :set_discount_coupon, only: [ :edit, :update, :destroy, :template ]

  def index
    @discount_coupons = current_store.discount_coupons.latest.paginate(page: params[:page], per_page: 10)
  end

  def show
  end

  def new
    @discount_coupon = DiscountCoupon.new
  end

  def edit

  end

  def create
    outcome = ::DiscountCoupons::CreateDiscountCoupon.run discount_coupon_params.delete_if {|k,v| v.blank?}.merge(store: @store).merge(coupon_code_params)

    @discount_coupon = outcome.result

    respond_to do |format|
      if outcome.valid?
        flash[:success] = 'Discount coupon created', :fade
        format.html { redirect_to back_discount_coupons_path }
      else
        format.html { render :new }
      end
    end
  end

  def update
    outcome = ::DiscountCoupons::UpdateDiscountCoupon.run(discount_coupon_params.delete_if {|k,v| v.blank?}
                                                          .merge(discount_coupon: @discount_coupon)
                                                          .merge(params[:coupon_code].present? ? coupon_code_params : {}))

    respond_to do |format|
      if outcome.valid?
        if discount_coupon_params[:status].present?
          flash[@discount_coupon.status_flash_type] = "Discount coupon #{@discount_coupon.status_text}", :fade
        else
          flash[:success] = 'Discount coupon updated', :fade
        end
        format.html { redirect_to back_discount_coupons_path }
      else
        format.html { render :edit }
      end
    end
  end

  def destroy
    flash[:info] = "Removed discount coupon with code #{ @discount_coupon.code }"
    @discount_coupon.destroy

    respond_to do |format|
      format.html { redirect_to back_discount_coupons_path }
      format.json { head :no_content }
    end
  end

  def template
    @promotion = current_store.promotions.new(starts_at: DateTime.current, ends_at: nil)
    @promotion.discount_coupons << @discount_coupon if @discount_coupon.present?
    @placeholders_hash = @promotion.placeholders_hash_with_empty_values
    @available_placeholders = @promotion.available_placeholders

    respond_to do |format|
      format.js
    end
  end

  def history
    @review_request_coupon_codes = ReviewRequestCouponCode.filtered(current_store: @store,
                                                                    term:          search_params[:term],
                                                                    filter_params: {},
                                                                    sort:          :latest,
                                                                    page:          params[:page],
                                                                    per_page:      10)
  end

  private

  def check_if_promotions_is_enabled
    redirect_to back_dashboard_index_path unless @store.promotions_enabled?
  end

  def set_discount_coupon
    @discount_coupon = current_store.discount_coupons.find_by_hashid(params[:id])
  end

  def discount_coupon_params
    params.require(:discount_coupon).permit(:name, :code_type, :valid_from, :valid_until, :discount_amount, :discount_type, :discount_sequence, :limit, :send_per, :status)
  end

  def coupon_code_params
    params.require(:coupon_code).permit!
  end

  def search_params
    params.permit(:term)
  end

end

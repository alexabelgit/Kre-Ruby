class Back::DiscountCoupons::CouponCodesController < Back::CommentsController

  before_action :set_discount_coupon, only: [:index, :destroy]
  before_action :set_coupon_code,     only: [:destroy]

  def index
    @coupon_codes = @discount_coupon.coupon_codes.by_usage_number.paginate(page: params[:page], per_page: 10).includes(:review_request_coupon_codes)
  end

  def destroy
    flash[:info] = "Removed coupon code #{ @coupon_code.code }"
    @coupon_code.destroy

    respond_to do |format|
      format.html { redirect_to back_discount_coupon_coupon_codes_path(@discount_coupon) }
      format.json { head :no_content }
    end
  end

  private

  def set_coupon_code
    @coupon_code = @discount_coupon.coupon_codes.find_by_hashid(params[:id])
  end

  def set_discount_coupon
    @discount_coupon = current_store.discount_coupons.find_by_hashid(params[:discount_coupon_id])
  end

end

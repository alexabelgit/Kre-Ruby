module Admin
  class PackageDiscountsController < AdminController
    include SelectOptions

    before_action :find_package_discount, only: [:edit, :update, :destroy]

    add_breadcrumb 'Admin', :admin_root_path
    add_breadcrumb 'Pricing', :admin_pricing_index_path

    def new
      @package_discount = PackageDiscount.new
      @ecommerce_platforms = ecommerce_platforms_select_options
    end

    def edit
      @ecommerce_platforms = ecommerce_platforms_select_options @package_discount.ecommerce_platform
    end

    def create
      inputs = params[:package_discount]
      outcome = PackageDiscounts::CreatePackageDiscount.run inputs
      if outcome.valid?
        redirect_to package_discounts_admin_pricing_index_path
      else
        @package_discount = outcome
        render :new
      end
    end

    def update
      inputs = { package_discount: @package_discount }
                 .reverse_merge(params[:package_discount])
      outcome = PackageDiscounts::UpdatePackageDiscount.run inputs
      if outcome.valid?
        redirect_to package_discounts_admin_pricing_index_path
      else
        flash[:error] = outcome.errors.full_messages.to_sentence
        @package_discount = outcome
        render :edit
      end
    end

    def destroy
      outcome = PackageDiscounts::DestroyPackageDiscount.run package_discount: @package_discount

      flash[:error] = outcome.errors.full_messages.to_sentence unless outcome.valid?
      redirect_to package_discounts_admin_pricing_index_path
    end

    private

    def find_package_discount
      @package_discount = PackageDiscount.find params[:id]
    end
  end
end

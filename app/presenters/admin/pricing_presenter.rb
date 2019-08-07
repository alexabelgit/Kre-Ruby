module Admin
  class PricingPresenter
    attr_reader :view, :params

    ADDONS_PER_PAGE            = 10
    PLANS_PER_PAGE             = 30
    PACKAGE_DISCOUNTS_PER_PAGE = 10

    def initialize(params, view = ActionView::Base)
      @params = params
      @view   = view
    end

    def navigation_items
      [
        {
          name:   'Plans',
          path:   view.admin_pricing_index_path,
          active: [['admin/pricing'], ['index']]
        },
        {
          name:   'Package discounts',
          path:   view.package_discounts_admin_pricing_index_path,
          active: :inclusive
        },
        {
          name:           'Addons',
          path:           view.addons_admin_pricing_index_path,
          active:         :inclusive,
          active_disable: true
        },
        {
          name:   'Coupons',
          path:   view.coupons_admin_pricing_index_path,
          active: :inclusive
        }
      ]
    end

    def addons
      Addon.paginate(page: params[:page], per_page: ADDONS_PER_PAGE)
    end

    def shopify_plans?
      params[:ecommerce_platform] == 'shopify'
    end

    def products_based_plans?
      params[:pricing_model] == 'products'
    end

    def plans
      plans = Plan.latest.includes(:ecommerce_platform).order('plans.created_at DESC')
      if params[:ecommerce_platform]
        plans = plans.joins(:ecommerce_platform).where('ecommerce_platforms.name = ?', params[:ecommerce_platform])
      end

      if params[:pricing_model]
        plans = plans.where(pricing_model: params[:pricing_model])
      end

      plans.paginate(page: params[:page], per_page: PLANS_PER_PAGE)
    end

    def package_discounts
      PackageDiscount.paginate(page: params[:page], per_page: PACKAGE_DISCOUNTS_PER_PAGE)
    end
  end
end

module Admin
  class PricingController < AdminController
    add_breadcrumb "Admin",   :admin_root_path
    add_breadcrumb "Pricing", :admin_pricing_index_path

    def index
      @presenter = build_pricing_presenter
    end

    def addons
      @presenter = build_pricing_presenter
    end

    def package_discounts
      @presenter = build_pricing_presenter
    end

    def coupons
      @presenter = build_pricing_presenter
    end

    def plans
      plans = Plan.where(id: params[:plan_ids])

      set_csv_headers
      csv = Export::PlansCsvExport.new(plans).generate
      respond_to do |format|
        format.csv { send_data csv, filename: "plans-export.csv" }
      end
    end

    private

    def build_pricing_presenter
      Admin::PricingPresenter.new params, view_context
    end

  end
end

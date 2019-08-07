module Admin
  class PlansController < AdminController
    include SelectOptions

    add_breadcrumb "Admin",   :admin_root_path
    add_breadcrumb "Pricing", :admin_pricing_index_path

    before_action :find_plan, only: [:edit, :update]

    def new
      add_breadcrumb "New plan", :new_admin_plan_path
      @plan = Plan.new ecommerce_platform: EcommercePlatform.shopify, overages_limit_in_cents: Rails.configuration.billing.default_overages_limit
      @platforms = ecommerce_platforms_select_options
    end

    def edit
      @platforms = ecommerce_platforms_select_options @plan.ecommerce_platform
    end

    def create
      inputs = params[:plan].reject { |_, v| v.blank? }
      outcome = Plans::CreatePlan.run inputs
      if outcome.valid?
        redirect_to admin_pricing_index_path
      else
        @plan = outcome
        @platforms = ecommerce_platforms_select_options
        render :new
      end
    end

    def update
      inputs = { plan: @plan }.reverse_merge(params[:plan]).reject { |k, v| v.blank? }
      outcome = Plans::UpdatePlan.run inputs
      if outcome.valid?
        redirect_to admin_pricing_index_path
      else
        flash[:error] = outcome.errors.full_messages.to_sentence
        @platforms = ecommerce_platforms_select_options
        @plan = outcome.plan
        render :edit
      end
    end

    private

    def find_plan
      @plan = Plan.find params[:id]
    end
  end
end

class Admin::AddonsController < AdminController
  add_breadcrumb "Admin",   :admin_root_path
  add_breadcrumb "Pricing", :admin_pricing_index_path

  before_action :find_addon, only: [:show, :edit, :update]

  def new
    add_breadcrumb "New addon", :new_admin_addon_path
    @addon = Addon.new
  end

  def edit
  end

  def show
  end

  def create
    outcome = Addons::CreateAddon.run(params[:addon])

    if outcome.valid?
      redirect_to admin_pricing_index_path
    else
      @addon = outcome
      render :new
    end
  end

  def update
    inputs = { addon: @addon }.reverse_merge(params[:addon])
    outcome = Addons::UpdateAddon.run(inputs)

    if outcome.valid?
      redirect_to admin_pricing_index_path
    else
      flash[:error] = outcome.errors.messages
      render :edit
    end
  end

  private

  def find_addon
    @addon = Addon.find params[:id]
  end
end

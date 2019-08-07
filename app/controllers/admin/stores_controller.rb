class Admin::StoresController < AdminController
  before_action :set_store, except: [:index]

  add_breadcrumb "Admin",  :admin_root_path
  add_breadcrumb "Stores", :admin_stores_path

  def index
    @search_term       = search_params[:term]
    @storefront_active = params[:storefront_active]
    @backend_active    = params[:backend_active]
    query = Admin::FindStores.new
    if @search_term.present?
      stores = Store.where(id: @search_term)
      if stores.present?
        query = Admin::FindStores.new(stores)
        @stores = query.call page: params[:page], storefront_active: @storefront_active, backend_active: @backend_active
      else
        @stores = query.call search_term: @search_term, page: params[:page], storefront_active: @storefront_active,
                             backend_active: @backend_active, joins: :user
      end
    else
      @stores = query.call page: params[:page], storefront_active: @storefront_active,
                           backend_active:@backend_active
    end
  end

  def show
    add_breadcrumb @store.name, admin_store_path(@store)
    @presenter = Admin::BillingPresenter.new @store, view_context
  end

  def update
    respond_to do |format|
      if @store.update(status_params)
        flash[:success] = 'Store status updated'
        format.html { redirect_to admin_store_path(@store) }
      else
        format.html { render 'back/settings/store' }
      end
      format.js
    end
  end

  def sync_products
    ImportProductsWorker.perform_async(@store.id)
    respond_to do |format|
      format.js
    end
  end

  def sync_shopify
    AfterShopifyStoreInstallWorker.perform_async(@store.id)
    respond_to do |format|
      format.js
    end
  end

  def withhold
    subscription = @store.active_subscription
    Subscriptions::WithholdSubscription.run subscription: subscription
    redirect_to admin_store_path(@store)
  end

  def release_hold
    subscription = @store.active_subscription
    Subscriptions::ReleaseSubscriptionHold.run subscription: subscription
    redirect_to admin_store_path(@store)
  end

  def settings
    add_breadcrumb @store.name, admin_store_path(@store)
    add_breadcrumb 'Settings', settings_admin_store_path(@store)
  end

  def update_settings
    respond_to do |format|
      if @store.settings(params[:type].to_sym).update(setting_params)
        flash[:success] = 'Changes saved'
        format.html { redirect_to settings_admin_store_path(@store) }
      else
        format.html { render params[:view] }
      end
    end
  end

  def check_widgets
    Widgets::Utils.check_in_use(store: @store, handle: params[:handle])
    redirect_to settings_admin_store_path(@store)
  end

  def anonymize
    outcome = Stores::AnonymizeStore.run store: @store
    if outcome.valid?
      flash[:success] = "Successfully anonymized customer emails"
    else
      flash[:error] = "Failed to anonymize some customer emails"
    end
    redirect_to admin_store_path(@store)
  end

  def delete_data
    outcome = Stores::Admin::ResetStoreData.run store: @store
    if outcome.valid?
      flash[:success] = "Successfully deleted all reviews and questions"
    else
      flash[:error] = "Failed to delete data"
    end
    redirect_to admin_store_path(@store)
  end

  def delete_imported_reviews
    outcome = Stores::Admin::ResetImportedReviews.run store: @store
    if outcome.valid?
      flash[:success] = "Successfully deleted all imported reviews"
    else
      flash[:error] = "Failed to delete data"
    end
    redirect_to admin_store_path(@store)
  end

  def extend_trial
    result = Stores::ExtendTrial.run extend_trial_params.merge(store: @store)
    if result.valid?
      flash[:success] = "Successfully extended trial until #{@store.trial_ends_at.to_date.to_formatted_s(:long)}"
    else
      flash[:error] = result.errors.full_messages unless result.valid?
    end
    redirect_to admin_store_path(@store)
  end

  def grant_orders
    result = Stores::GrantOrders.run grant_orders_params.merge(store: @store)
    if result.valid?
      flash[:success] = "Successfully granted free orders to store"
    else
      flash[:error] = result.errors.full_messages unless result.valid?
    end
    redirect_to admin_store_path(@store)
  end

  def grant_products
    result = Stores::GrantProducts.run grant_products_params.merge(store: @store)

    if result.valid?
      flash[:success] = "Successfully granted free products to store"
    else
      flash[:error] = result.errors.full_messages unless result.valid?
    end
    redirect_to admin_store_path(@store)
  end

  def export_products
    report = Export::StoreProductsExport.new(@store).create_report
    respond_to do |format|
      format.csv { send_data report, filename: "store-#{@store.hashid}-products.csv" }
    end
  end

  def grant_translator_permissions
    user = @store.user

    user.translator! if user.standard?
    redirect_to admin_store_path(@store)

  end

  def remove_translator_permissions
    user = @store.user

    user.standard! if user.translator?
    redirect_to admin_store_path(@store)
  end

  def change_pricing_model
    @store.update pricing_model_params
    message = "Store pricing is switched to #{@store.pricing_model.to_s} based. "
    if @store.subscription?
      next_billing_date = @store.active_subscription.next_billing_at.to_date.to_formatted_s(:short)
      message << "Please ensure that store owner selects new plan before #{next_billing_date}"
    end
    flash[:success] = message
    redirect_to admin_store_path(@store)
  end

  protected

  def setting_params
    params.require(:settings).permit!
  end

  def set_store
    @store = Store.find_by_hashid(params[:id])
    Time.zone = @store.time_zone
  end

  def search_params
    params.permit(:term)
  end

  def extend_trial_params
    params.require(:store).permit(:new_trial_date)
  end

  def grant_orders_params
    params.require(:store).permit(:amount)
  end

  def grant_products_params
    params.require(:store).permit(:amount, :valid_till)
  end

  def status_params
    params.require(:store).permit(:storefront_status, :status)
  end

  def pricing_model_params
    params.require(:store).permit(:pricing_model)
  end
end

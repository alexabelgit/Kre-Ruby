class Back::LemonstandSetupController < BackController
  before_action      :check_user_installed, only: [:create]
  before_action      :set_domain,           only: [:create, :update]

  def create
    store = Store.find_by_id_from_provider(@domain)

    if store.present?
      flash[:error] = I18n.t("oauth.errors.store_already_connected", store_name: store.name, email: store.user.email)
      redirect_to connect_with_lemonstand_back_stores_path
      return
    end

    unless store_exists_on_lemonstand?
      flash[:error] = I18n.t("oauth.errors.invalid_site")
      redirect_to connect_with_lemonstand_back_stores_path
      return
    end

    store_params = {
      id_from_provider: @domain,
      access_token:     received_store_params[:access_token],
      provider:         'lemonstand',
      url:              received_store_params[:url],
      domain:           "#{@domain}.lemonstand.com",
      name:             @domain,
      legal_name:       @domain,
      installed_at:     DateTime.current,
      user:             current_user
    }
    outcome = Stores::CreateStore.run store_params

    unless outcome.valid?
      flash[:error] = outcome.errors.full_messages.to_sentence
      redirect_to connect_with_lemonstand_back_stores_path
      return
    end

    store = outcome.result
    sync(store)

    flash[:success] = I18n.t("oauth.lemonstand.landing.connected.html", store_name: store.name)
    redirect_to onboarding_back_tools_path
  end

  def update
    store = current_user.store
    redirect_to reconnect_with_lemonstand_back_stores_path unless store.present?

    unless store_exists_on_lemonstand?
      flash[:error] = I18n.t("oauth.errors.invalid_site")
      redirect_to reconnect_with_lemonstand_back_stores_path
      return
    end

    if store.update_attributes(access_token:     received_store_params[:access_token],
                               url:              received_store_params[:url],
                               id_from_provider: @domain,
                               domain:           "#{@domain}.lemonstand.com",
                               name:             @domain,
                               legal_name:       @domain)
      sync(store)

      flash[:success] = I18n.t("oauth.lemonstand.landing.reconnected", store_name: store.name)
      redirect_to root_path
    else
      flash[:error] = I18n.t("oauth.errors.cannot_reconnect_store")
      redirect_to reconnect_with_lemonstand_back_stores_path
    end
  end

  private

  def received_store_params
    params.require(:store).permit(:url, :id_from_provider, :access_token)
  end

  def check_user_installed
    redirect_to action: "update" if current_user.installed?
  end

  def set_domain
    @domain = received_store_params[:id_from_provider].strip
  end

  def store_exists_on_lemonstand?
    result = LemonstandAPI::Product.new(nil,
                                        domain:       "#{@domain}.lemonstand.com",
                                        access_token: received_store_params[:access_token]
                                       ).all
    return result.present?
  end

  def sync(store)
    sync_service = Sync::LemonstandService.new(store: store)
    sync_service.webhooks
  end

end

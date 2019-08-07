class Back::StoresController < BackController
  skip_before_action :check_live
  before_action      :adjust_connect_path,     only: [:connect_store, :connect_with_custom_website, :connect_with_ecwid, :connect_with_lemonstand, :reconnect_with_lemonstand, :connect_with_shopify]
  before_action      :set_store,               only: [:update, :reconnect_with_lemonstand]
  before_action      :reject_custom_reconnect, only: [:create, :connect_with_custom_website]

  def create
    posted_params =
      {
        id_from_provider: SecureRandom.uuid,
        access_token:     SecureRandom.uuid,
        provider:         'custom',
        url:              create_store_params[:url],
        name:             create_store_params[:name],
        legal_name:       create_store_params[:name],
        installed_at:     DateTime.current,
        user:             current_user
      }

    outcome = Stores::CreateStore.run posted_params

    unless outcome.valid?
      flash[:error] = outcome.errors.full_messages.to_sentence
      redirect_to connect_back_stores_path
      return
    end

    flash[:success] = I18n.t('oauth.custom.connected.html', store_name: current_store.name)
    redirect_to onboarding_back_tools_path
  end

  def update
    respond_to do |format|
      if @store.update(store_params)
        complete_global_settings_customized_step
        flash[:success] = 'Settings updated'
        format.html { redirect_to general_back_settings_path }
      else
        format.html { render 'back/settings/general' }
      end
      format.js
    end
  end

  def connect_store
  end

  def connect_with_custom_website
    @store = Store.new
  end

  def connect_with_ecwid
  end

  def connect_with_lemonstand
  end

  def reconnect_with_lemonstand
  end

  def connect_with_shopify
  end

  private

  def adjust_connect_path
    # Return if there is no store because in that case any platform is
    # acceptable and we don't want to and cannot adjust anything here
    return unless current_store

    path = helpers.connect_store_path(current_store)

    unless helpers.current_page?(path)
      if flash.empty? && !params[:error]
        flash[:warning] = "Your cannot change website platform. Please reconnect with existing one"
      end
      redirect_to path
    end
  end


  def create_store_params
    params.require(:store).permit(:name, :url)
  end

  def store_params
    allowed_params = %i[name url logo logo_cache status storefront_status legal_name]
    allowed_params << :access_token if @store&.lemonstand?
    params.require(:store).permit(allowed_params)
  end

  def reject_custom_reconnect
    # TODO
    # This is a temporary solution for custom stores. Once we introduce public
    # API, we should no longer redirect custom stores away from this page because
    # they will need to provide access_token and maybe other fields as well.
    # right now, this redirect was a quick and dirty fix for the even dirtier
    # thing we have here with create / update actions. Shortly, if we remove this
    # redirection and someone tries to reconnect a custom website, there will be
    # an exception because we will try to create a new store record
    if current_store
      flash[:notice] = "You can update your store information on this page"
      redirect_to general_back_settings_path
    end
  end
end

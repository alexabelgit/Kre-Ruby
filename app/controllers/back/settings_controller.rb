class Back::SettingsController < BackController
  skip_before_action :check_live, only: :billing

  def billing
    if current_store.can_be_billed?
      @presenter = BillingPresenter.new current_store, view_context
    else
      render 'static_billing'
    end
  end

  def design
  end

  def onboarding
  end

  def questions
  end

  def reviews
  end

  def social_accounts
  end

  def promotions
  end

  def store
  end

  def widgets
  end

  def select_facebook_page
    page_id = setting_params[:facebook_page_id]
    if setting_params[:facebook_pages].present?
      selected_page = setting_params[:facebook_pages].find { |p| p[:id] == page_id }
    end
    if selected_page.present?
      page_name = selected_page[:name]

      current_user.store.settings(:social_accounts).update_attributes(facebook_page_id:   page_id,
                                                                      facebook_page_name: page_name)

      flash[:success] = 'Facebook page selected'
    else
      flash[:error] = 'Please choose a Facebook page associated with your store'
    end
    redirect_to social_accounts_back_settings_path
  end

  def update
    respond_to do |format|
      @store.change_template_language(setting_params[:locale]) if params[:change_templates].present? && params[:change_templates].to_b

      if setting_params[:reviews_facebook_tab].present?
        unless @store.facebook_active?
          flash[:warning] = 'You first need to connect your Facebook page to your HelpfulCrowd account'
          redirect_to social_accounts_back_settings_path
          return
        end
        if setting_params[:reviews_facebook_tab].to_b
          @store.koala_page.put_connections('me', 'tabs', app_id: ENV['FACEBOOK_APP_ID'])
        else
          @store.koala_page.delete_connections('me', 'tabs', tab: "app_#{ENV['FACEBOOK_APP_ID']}", app_id: ENV['FACEBOOK_APP_ID'])
        end
      end

      if @store.settings(params[:type].to_sym).update_attributes(setting_params)
        complete_global_settings_customized_step if setting_params[:default_name].present? || setting_params[:time_zone].present? || setting_params[:notify_customers_at]
        flash[:success] = 'Changes saved', :fade
        format.html { redirect_to params[:redirect_to] }
        format.js   { render inline: redirect_js(params[:redirect_to] || request.referer || root_url) }
      else
        format.html { render params[:view] }
        format.js   { render inline: redirect_js(params[:redirect_to] || request.referer || root_url) }
      end
    end
  end

  private

  def setting_params
    params.require(:settings).permit!
  end

  def store_params
    params.require(:store).permit(:name, :url, :logo, :logo_cache)
  end

  def seed_params
    params.require(:seed).permit(:date_from, :date_to)
  end
end

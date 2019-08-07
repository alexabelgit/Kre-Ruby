class Front::PluginsController < FrontController

  def display_name
    @hint = params[:name].blank? ? I18n.t('hint', scope: 'front.components.customer_form.name') :
                                   I18n.t('hint_update_html', scope: 'front.components.customer_form.name', initials: params[:name].as_display_name(@store.settings(:customers).display_name_policy))
    @form_id = params[:form_id]
    respond_to do |format|
      format.js
    end
  end
end

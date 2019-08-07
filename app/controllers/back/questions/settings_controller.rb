class Back::Questions::SettingsController < Back::SettingsController

  def email_templates

  end

  def update_email_templates
    @store.settings(:questions).update_attributes(setting_params)
    hide_check_announcement
  end

  def social_templates
  end

  def hide_check_announcement
    @store.update_settings(:questions, check_required: false)
  end

  def update_social_templates
    respond_to do |format|
      if @store.settings(:questions).update_attributes(setting_params)
        flash[:success] = 'Social templates updated', :fade

        format.html { redirect_to social_templates_back_questions_path }
      else
        format.html { render :social_templates }
      end
    end
  end

end

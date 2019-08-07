class Callbacks::FacebookController < CallbacksController
  def reviews_tab
    if params[:signed_request]
      signed_request  = params[:signed_request]
      @oauth          = Koala::Facebook::OAuth.new(ENV['FACEBOOK_APP_ID'], ENV['FACEBOOK_APP_SECRET'])
      page_id         = @oauth.parse_signed_request(signed_request)['page']['id']
      like_statement  = "facebook_page_id: ''#{page_id}''"
      settings_object = SettingsObject.where(var: 'social_accounts').where("value LIKE '%#{like_statement}%'").first

      if settings_object.present?
        store = settings_object.target

        redirect_to reviews_facebook_tab_front_widgets_url(store)
      end
    end
  end
end

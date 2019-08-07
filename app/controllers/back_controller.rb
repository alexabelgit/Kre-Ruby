class BackController < ApplicationController
  before_action :authenticate_user!
  before_action :redirect_to_connect_page, unless: :current_store
  before_action :set_store,
                :set_time_zone,
                :set_announcements,
                :check_live

  rescue_from Koala::KoalaError, with: :koala_error   unless Rails.env.development?
  rescue_from Twitter::Error,    with: :twitter_error unless Rails.env.development?

  layout 'back'

  protected

  def complete_global_settings_customized_step # TODO separated from onboardable
    @store.settings(:onboarding).update_attributes(global_settings_customized: true)
  end

  private

  def redirect_to_connect_page
    # Return if connect is what the user is trying to achieve
    return if
      helpers.current_page?(connect_back_stores_path)                     ||
      helpers.current_page?(connect_with_custom_website_back_stores_path) ||
      (controller_name == "stores" && action_name == "create")            ||
      helpers.current_page?(connect_with_ecwid_back_stores_path)          ||
      helpers.current_page?(connect_with_lemonstand_back_stores_path)     ||
      controller_name == "lemonstand_setup" && action_name == "create"    ||
      helpers.current_page?(connect_with_shopify_back_stores_path)

    if flash.empty? && !params[:error]
      flash[:warning] = 'To continue please connect your HelpfulCrowd account with your website'
    end
    redirect_to connect_back_stores_path
  end

  def impersonated_as_user_with_store?
    current_user.store.present? && true_user.present? && true_user != current_user
  end

  def current_store
    current_user.store
  end

  def set_store
    @store = current_store
  end

  def check_live
    return true if current_user.admin?

    redirect_to billing_back_settings_path if @store.present? && !@store.live?
  end

  def set_announcements
    @announcements = AnnouncementBuilder.new(current_store, view_context).announcements
  end

  def set_time_zone
    return if current_store.blank?
    Time.zone = current_store.time_zone
  end

  def koala_error(e)
    case e
    #TODO change error messages via en.yml
    when Koala::Facebook::AuthenticationError
      current_user.social_accounts.facebook.each do |fb_account|
        fb_account.destroy
      end
      flash[:error] = 'Request failed: you need to install HelpfulCrowd app on your Facebook account.'
    when Koala::Facebook::APIError
      flash[:error] = 'Request failed: HelpfulCrowd app has insufficient permissions on your Facebook account.' if (200..299).include?(e.fb_error_code)
      flash[:error] = 'Request failed: duplicate post.' if e.fb_error_code == 506
      flash[:error] = 'We could not install custom tab on your Facebook page. Make sure you are allowed to add 3rd party tabs and try again.' if e.fb_error_code == 2069016
    end

    Rails.logger.error { "#{e.message} #{e.backtrace.join("\n")}" } # TODO @nkadze should this be removed or is it needed?
    respond_to do |format|
      format.html { redirect_to request.referer || root_url }
      format.js { render inline: redirect_js(request.referer || root_url) }
    end
  end

  def twitter_error(e)
    case e
    #TODO change error messages via en.yml
    when Twitter::Error::Unauthorized
      current_user.social_accounts.twitter.each do |fb_account|
        fb_account.destroy
      end
      flash[:error] = 'Request failed: you need to install HelpfulCrowd app on Twitter account.'
    else
      flash[:error] = 'Request failed: invalid tweet or bad request'
    end

    Rails.logger.error { "#{e.message} #{e.backtrace.join("\n")}" }
    respond_to do |format|
      format.html { redirect_to request.referer || root_url }
      format.js { render inline: redirect_js(request.referer || root_url) }
    end
  end
end

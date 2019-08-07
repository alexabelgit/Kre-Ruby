class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController

  before_action :authenticate_user!

  def provider
    current_user.from_omniauth(request.env['omniauth.auth']) if current_user.present?

    case __callee__.to_s
    when 'facebook'
      flash[:info] = "HelpfulCrowd successfully connected with your Facebook account. Select your store page to complete setup."
      redirect_to social_accounts_back_settings_url(anchor: __callee__.to_s)

    when 'twitter'
      flash[:success] = "HelpfulCrowd successfully connected with your Twitter account."
      redirect_to social_accounts_back_settings_url
    end
  end

  alias_method :twitter,  :provider
  alias_method :facebook, :provider

  def failure
    flash[:danger] = "Authentication attempt failed, please try again."
    redirect_to social_accounts_back_settings_url
  end

end

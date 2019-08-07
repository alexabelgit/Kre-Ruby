class ApplicationController < ActionController::Base
  prepend_before_action :set_locale

  before_action     :prepare_raven
  before_action     :configure_permitted_parameters, if: :devise_controller?
  skip_after_action :intercom_rails_auto_include,    if: -> { true_user.present? && true_user != current_user }

  protect_from_forgery with: :exception
  impersonates         :user

  include ShopifyEmbeddedAuthCheck

  def not_found
    raise ActionController::RoutingError.new('Not Found')
  end

  def default_url_options
    if Rails.env.development? && ENV['NGROK_ON'].present? && ENV['NGROK_ON'].to_b
      { host: ENV['NGROK_HOST'], port: nil }
    else
      super
    end
  end

  protected

  def redirect_js(path)
    "jQuery(window.location.replace(\"#{path}\"));"
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up) do |u|
      u.permit(:first_name, :last_name, :email, :password, :password_confirmation, :terms_and_privacy)
    end

    devise_parameter_sanitizer.permit(:account_update) do |u|
      u.permit(:first_name, :last_name, :email, :password, :password_confirmation, :current_password)
    end
  end

  private

  def set_locale
    I18n.locale = :en
  end

  def after_sign_out_path_for(resource_or_scope)
    new_session_path(resource_or_scope)
  end

  def prepare_raven
    user = request.env['warden'].user
    if user.present?
      store = user.store
      Raven.user_context(
        id:         user.id,
        email:      user.email,
        first_name: user.first_name,
        last_name:  user.last_name,
        store_name: (store.present? ? store.name : nil),
        store_id:   (store.present? ? store.id   : nil),
        store_url:  (store.present? ? store.url  : nil),
        ip_address: request.ip
      )
    end
  end
end

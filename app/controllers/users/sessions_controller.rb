class Users::SessionsController < Devise::SessionsController
  after_action :prepare_intercom_shutdown, only: [:destroy]
  after_action :intercom_shutdown,         only: [:new    ]
  after_action :track_events,              only: [:create]

  def new
    super
  end

  def sign_in_with_shopify
  end

  def create
    user = User.find_by_email(params[:user][:authentication_key])
    if user.present? && user.multiple_account_per_email_allowed?
      BackMailer.require_oauth_instead_of_email_auth(user.store.id).deliver if user.valid_password?(params[:user][:password])
      super
    else
      self.resource = warden.authenticate!(auth_options)
      if self.resource.deleted?
        self.resource.reactivate
        flash[:success] = I18n.t('devise.registrations.reactivated')
      end
      super
    end
  end

  def destroy
    super
  end

  def problems
    render 'devise/sessions/sign_in_problems'
  end

  protected
  def prepare_intercom_shutdown
    IntercomRails::ShutdownHelper.prepare_intercom_shutdown(session)
  end

  def intercom_shutdown
    IntercomRails::ShutdownHelper.intercom_shutdown(session, cookies)
  end

  private
  def after_sign_in_path_for(resource)
    super
  end

  def track_events
    if current_user.present?
      ahoy.track 'sign in', user_id: resource.id, referrer: 'with email'
    end
  end

end

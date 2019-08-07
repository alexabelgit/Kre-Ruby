class Users::PasswordsController < Devise::PasswordsController

  def create
    user = User.find_by_email(resource_params[:email])
    if user&.multiple_account_per_email_allowed?
      BackMailer.require_oauth_instead_of_email_auth(user.store.id).deliver
      flash[:notice] = I18n.t('devise.passwords.send_paranoid_instructions')
      redirect_to new_user_session_path
    else
      super
    end
  end

end

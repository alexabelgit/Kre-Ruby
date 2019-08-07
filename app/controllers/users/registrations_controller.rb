class Users::RegistrationsController < Devise::RegistrationsController
  after_action :track_events, only: [:create]

  def new
    super
  end

  def create
    super
  end

  def sign_up_with_shopify
  end

  def destroy
    resource.deactivate

    Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name)
    set_flash_message :notice, :deactivated if is_flashing_format?

    yield resource if block_given?

    respond_with_navigational(resource) do
      redirect_to after_sign_out_path_for(resource_name)
    end
  end

  private

  def after_update_path_for(resource)
    edit_user_registration_path
  end

  def track_events
    if current_user.present?
      ahoy.track 'sign up', user_id: resource.id, referrer: 'with email'
    end
  end
end

class EcwidInitializationService < OauthInitializationService
  attr_reader :store_id, :store, :ecwid_profile
  attr_reader :store, :ecwid_profile
  attr_reader :authenticated_user

  def initialize(token, store_id, authenticated_user)
    @token              = token
    @store_id           = store_id
    @authenticated_user = authenticated_user
    @ecwid_profile      = EcwidProfile.new(token, store_id)
    @store              = Store.find_by id_from_provider: store_id
  end

  def call(initialized_from_ecwid)
    return Result.new(success: false, status: ecwid_profile.error_code, error: ecwid_profile.error_message) unless ecwid_profile.present?

    source = oauth_source initialized_from_ecwid
    result = store.blank? ? initialize_store(source) : sign_in_existing_store(store, source)
    ensure_store_and_user_valid(result.entity) if result.success?

    result
  end

  protected

  def ecommerce_platform
    EcommercePlatform.ecwid
  end

  private

  def initialize_store(source)
    result = select_user_to_create_store_with(source)
    return result unless result.success?

    create_store_outcome = create_store(ecwid_profile, user)
    unless create_store_outcome.valid?
      error_message = create_store_outcome.errors.full_messages
      return cannot_create_store_error(error_message)
    end

    @store = create_store_outcome.result

    successfully "#{source}_sign_up".to_sym, store
  end

  def select_user_to_create_store_with(source)
    if authenticated_user_does_not_have_store?
      @user = authenticated_user
    else
      @user = User.find_by email: ecwid_profile.account_email
      return account_exists_error(source) if user_already_has_store?(@user)
      unless user.present?
        @user = create_user
        return cannot_create_user_error(user) unless @user.persisted?
      end
    end
    Result.new success: true, entity: @user
  end

  def create_user
    first_name, last_name = ecwid_profile.account_first_and_last_name

    params =
      {
        email:      ecwid_profile.account_email,
        password:   generate_password,
        first_name: first_name,
        last_name:  last_name
      }

    User.create_without_confirmation(params).tap do |user|
      user.admin! if Rails.configuration.user_as_admin_by_default
    end
  end

  def account_exists_error(source)
    error = I18n.t("oauth.errors.#{source}_account_exists", email: ecwid_profile.account_email.mask_email)
    Result.new(success: false, error: error, status: "#{source}_account_exists".to_sym)
  end

  def create_store(ecwid_profile, user)
    params =
      {
        id_from_provider: store_id.to_s,
        access_token:     token,
        provider:         'ecwid',
        url:              ecwid_profile.store_url,
        phone:            ecwid_profile.phone,
        legal_name:       ecwid_profile.legal_name,
        name:             ecwid_profile.store_name,
        remote_logo_url:  ecwid_profile.invoice_logo_url,
        installed_at:     DateTime.current,
        timezone:         ecwid_profile.timezone,
        user:             user
      }

    Stores::CreateStore.run params
  end
end

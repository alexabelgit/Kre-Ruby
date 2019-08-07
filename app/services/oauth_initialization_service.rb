class OauthInitializationService
  include WithPassword

  attr_reader :user, :token

  protected

  def ecommerce_platform
    nil
  end

  def sign_in_existing_store(store, source)
    return store_already_connected_error(store) if authenticated_user_has_different_store?(store)

    store.user.skip_confirmation!
    store.user.save!

    successfully "#{source}_sign_in".to_sym, store
  end

  def oauth_source(initalized_from_platform)
    return :tab if initalized_from_platform
    authenticated_user.present? ? :app : :landing
  end

  def user_already_has_store?(user)
    user.present? && user.store.present?
  end

  def authenticated_user_does_not_have_store?
    authenticated_user.present? && authenticated_user.store.blank?
  end

  def authenticated_user_has_different_store?(store)
    authenticated_user.present? && authenticated_user != store.user && authenticated_user.email != store.user.email
  end

  def successfully(status, store)
    Result.new success: true, entity: store, status: status
  end

  def store_already_connected_error(store)
    error = I18n.t("oauth.errors.store_already_connected",
                   store_name: store.name,
                   email:      store.user.masked_email)

    Result.new success: false,
               error:   error,
               status:  :store_already_connected
  end

  def cannot_create_store_error(errors)
    base_error = I18n.t("oauth.errors.cannot_create_store")
    error      = [base_error, errors].flatten.join('. ')

    Result.new success: false,
               entity:  nil,
               error:   error,
               status:  :cannot_create_store
  end

  def account_exists_error(email)
    Result.new success: false,
               error:   I18n.t("oauth.errors.account_exists", email: email.mask_email),
               status:  :account_exists
  end

  def cannot_create_user_error(user)
    Result.new success: false,
               error:   user.errors.full_messages,
               status:  :cannot_create_user
  end

  def ensure_store_and_user_valid(store)
    store.install(access_token: token, ecommerce_platform: ecommerce_platform) unless store.installed?

    store.user.reactivate if store.user.deleted? # reactivate user if it was deleted and import products for store
  end
end

class ShopifyInitializationService < OauthInitializationService
  attr_reader :store_domain, :authenticated_user

  def initialize(authenticated_user, token, store_domain)
    @authenticated_user = authenticated_user
    @token              = token
    @store_domain       = store_domain
  end

  def call(initialized_from_shopify)
    store_info = fetch_store_info store_domain, token
    store      = fetch_store store_info
    source = oauth_source initialized_from_shopify
    result = store.blank? ? initialize_store(store_info, source) : sign_in_existing_store(store, source)

    ensure_store_and_user_valid(result.entity) if result.success?

    result
  end

  protected

  def ecommerce_platform
    EcommercePlatform.shopify
  end

  private

  def initialize_store(store_info, source)
    result = select_user_to_create_store_with store_info
    return result unless result.success?

    create_store_outcome = create_store(store_info, user)

    unless create_store_outcome.valid?
      error_message = create_store_outcome.errors.full_messages
      return cannot_create_store_error(error_message)
    end

    store = create_store_outcome.result
    AfterShopifyStoreInstallWorker.perform_async(store.id)
    successfully "#{source}_sign_up".to_sym, store
  end

  def select_user_to_create_store_with(info)
    if authenticated_user_does_not_have_store?
      @user = authenticated_user
    else
      @user = User.includes(:store).where.not(stores: {ecommerce_platform: EcommercePlatform.send('shopify')})
                                   .find_by(email: info.email)
      return account_exists_error(info.email) if user_already_has_store?(@user)

      unless user.present?
        @user = create_user(info)
        cannot_create_user_error(user) unless user.persisted?
      end
    end
    Result.new success: true, entity: @user
  end

  def fetch_store(store_info)
    Store.shopify.find_by id_from_provider: store_info.id.to_s
  end

  def fetch_store_info(store_domain, token)
    ShopifyAPI::Session.temp(domain: store_domain, token: token, api_version: Shopify::ApiWrapper::API_VERSION) do
      ShopifyAPI::Shop.current
    end
  end

  def create_user(store_info)

    first_name = store_info.name                             # TODO
    last_name  = store_info.name                             # Short term: this probably needs to be a global method that returns first and last names from a string
    if store_info.shop_owner.present?                        #
      full_name  = store_info.shop_owner.strip.split(' ', 2) # Long term: we should rethink having first and last names. It would give some benefits if we
      first_name = full_name.first                           #            had only one field for full name (and we could have an extra field for 'preferred way to address you')
      last_name  = full_name.last                            #
    end

    skip_email_validation = Store.where.not(ecommerce_platform: EcommercePlatform.send('shopify')).includes(:user)
                                 .where(users: {email: store_info.email}).empty?
    params = {
      email:      store_info.email,
      password:   generate_password,
      first_name: first_name,
      last_name:  last_name,
      skip_email_validation: skip_email_validation,
      authentication_key: @store_domain
    }

    User.create_without_confirmation(params).tap do |user|
      user.admin! if Rails.configuration.user_as_admin_by_default
    end
  end

  def create_store(store_info, user)
    store_params = {
      id_from_provider: store_info.id.to_s,
      access_token:     token,
      provider:         'shopify',
      url:              "https://#{store_domain}",
      domain:           store_domain,
      phone:            store_info.phone,
      legal_name:       store_info.name,
      name:             store_info.name,
      plan_name:        store_info.plan_name,
      installed_at:     DateTime.current,
      timezone:         store_info.iana_timezone,
      user:             user
    }
    Stores::CreateStore.run store_params
  end

  def has_timezone?(store_info)
    ActiveSupport::TimeZone[store_info.iana_timezone].present?
  end
end

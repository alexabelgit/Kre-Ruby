class User < ApplicationRecord

  include Filterable

  ## Callbacks

  after_create_commit  :intercom_create_sync
  after_destroy        :intercom_destroy_sync, :destroy_store

  ## Associations
  has_one  :store
  has_many :comments
  has_many :social_accounts, dependent: :destroy

  ## Enums
  enum role: [ :standard, :admin, :translator ]

  ## Scopes
  scope :with_store, -> { joins(:store) }

  ## Devise
  devise :confirmable,
         :lockable,
         :registerable,
         :recoverable,
         :rememberable,
         :trackable,
         :validatable,
         :database_authenticatable, authentication_keys: [:authentication_key]
       # :timeoutable

  ## Validations
  validates_presence_of   :first_name, :last_name
  validates_acceptance_of :terms_and_privacy, message: "^You must read and agree to terms of service and privacy policy"

  # Multiple accounts
  validates :email, uniqueness: true, unless: :skip_email_validation
  scope :recently_updated,          -> { where('updated_at > ?', 12.hours.ago) }

  def skip_email_validation=(skip_email_validation)
    @skip_email_validation = skip_email_validation
  end

  def skip_email_validation
    multiple_account_per_email_allowed?
  end

  def authentication_key=(authentication_key)
    @authentication_key = authentication_key
  end

  def authentication_key
    @authentication_key || (shopify? ? store.id_from_provider : email)
  end

  def email_required?
    !multiple_account_per_email_allowed?
  end

  def will_save_change_to_email?
    (persisted? && saved_change_to_email? || !multiple_account_per_email_allowed?) && will_save_change_to_attribute?(:email)
  end

  def send_password_change_notification?
    super && !multiple_account_per_email_allowed?
  end

  def multiple_account_per_email_allowed?
    @skip_email_validation || shopify?
  end

  def shopify?
    !!store&.shopify?
  end

  def multiple_by_email?
    User.where(email: email).count >= 2
  end

  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    result = nil
    if authentication_key = conditions.delete(:authentication_key)
      user = where(conditions.to_h).where(["lower(email) = :value", { value: authentication_key.downcase }]).first
      result = user unless user&.multiple_account_per_email_allowed?
    end
    result
  end

  def valid_for_authentication?
    multiple_account_per_email_allowed? || super
  end

  def installed?
    store.present? && store.installed?
  end

  def display_name
    if first_name.present? && last_name.present?
      "#{first_name} #{last_name.first}.".titleize
    else
      self.email
    end
  end

  def display_initials
    if first_name.present? && last_name.present?
      "#{first_name.first}#{last_name.first}".upcase
    end
  end

  def full_name
    "#{first_name} #{last_name}".titleize
  end

  def masked_email
    email.mask_email
  end

  def self.create_without_confirmation(params)
    new(params).tap do |user|
      user.skip_confirmation!
      user.save
    end
  end

  def from_omniauth(auth)
    oauth_user = SocialAccount.where(user_id:  self.id,
                                     provider: auth.provider,
                                     uid:      auth.uid).first
    if oauth_user.present?
      oauth_user.update_attributes(access_token:  auth.credentials.token,
                                   access_secret: auth.credentials.secret)
    else
      oauth_user = self.social_accounts.create({ provider:      auth.provider,
                                                 uid:           auth.uid,
                                                 access_token:  auth.credentials.token,
                                                 access_secret: auth.credentials.secret })
    end

    if oauth_user.twitter?
      twitter_user = twitter_client.user
      store.update_settings :social_accounts,
                            twitter_user_id: twitter_user.id,
                            twitter_username: twitter_user.name,
                            twitter_screen_name: twitter_user.screen_name
    end
    oauth_user
  end

  def deleted?
    deleted_at.present?
  end

  def deactivate
    Users::DeactivateUser.run user: self
  end

  def reactivate
    Users::ReactivateUser.run user: self
  end

  def inactive_message
  	!deleted_at ? super : :deleted_account
  end

  # Facebook methods
  def facebook_connected?
    social_accounts.facebook.any?
  end

  def facebook_account
    self.social_accounts.facebook.first
  end

  def koala(access_token = nil)
    access_token ||= facebook_account.access_token
    Koala::Facebook::API.new(access_token) if facebook_connected?
  end

  def koala_page
    page_token = koala.get_page_access_token(store.settings(:social_accounts).facebook_page_id)
    koala page_token
  end

  def facebook_pages
    koala.get_connections('me', 'accounts') if facebook_connected?
  end

  # Twitter methods
  def twitter_connected?
    social_accounts.twitter.any?
  end

  def twitter_account
    social_accounts.twitter.first
  end

  def twitter_client
    return false unless twitter_connected?
    Twitter::REST::Client.new do |config|
       config.consumer_key        = ENV['TWITTER_API_KEY']
       config.consumer_secret     = ENV['TWITTER_API_SECRET']
       config.access_token        = twitter_account.access_token
       config.access_token_secret = twitter_account.access_secret
    end
  end

  # Pinteresting methods

  def pinterest_connected?
    social_accounts.pinterest.any?
  end

  protected

  def send_devise_notification(notification, *args)
    DeviseWorker.perform_async(devise_mailer, notification, id, *args)
  end

  def destroy_store
    store.destroy if store.present?
  end

  def intercom_create_sync
    CreateIntercomUserWorker.perform_async id
  end

  def intercom_destroy_sync
    DestroyIntercomUserWorker.perform_async id
  end
end

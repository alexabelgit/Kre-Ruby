class IntercomUser
  attr_reader :intercom_user

  def initialize(intercom_user)
    @intercom_user = intercom_user
  end

  def self.build_params(user)
    {
      user_id:           user.id,
      signed_up_at:      user.created_at,
      email:             user.email,
      name:              user.full_name,
      last_request_at:   user.current_sign_in_at,
      last_seen_ip:      user.current_sign_in_ip.to_s,
      custom_attributes: {
        sign_in_count:      user.sign_in_count,
        current_sign_in_at: user.current_sign_in_at,
        current_sign_in_ip: user.current_sign_in_ip.to_s,
        facebook_connected: false,
        twitter_connected:  false
      }
    }
  end

  def update(user)
    update_base_attributes user
    update_custom_attributes user
    intercom_user
  end

  private

  def update_base_attributes(user)
    intercom_user.signed_up_at    = user.created_at
    intercom_user.email           = user.email
    intercom_user.name            = user.full_name
    intercom_user.last_request_at = user.current_sign_in_at
    intercom_user.last_seen_ip    = user.current_sign_in_ip.to_s
    intercom_user.phone           = user.store.phone if user.store.present?
  end

  def update_custom_attributes(user)
    add_custom_attribute 'sign_in_count',       user.sign_in_count
    add_custom_attribute 'current_sign_in_at',  user.current_sign_in_at
    add_custom_attribute 'current_sign_in_ip',  user.current_sign_in_ip.to_s
    add_custom_attribute 'deactivated_at',      user.deleted_at
    add_custom_attribute 'last_sign_in_at',     user.last_sign_in_at
    add_custom_attribute 'last_sign_in_ip',     user.last_sign_in_ip.to_s
    add_custom_attribute 'facebook_connected',  user.facebook_connected?
    add_custom_attribute 'twitter_connected',   user.twitter_connected?
  end

  def add_custom_attribute(key, value)
    intercom_user.custom_attributes[key] = value
  end
end

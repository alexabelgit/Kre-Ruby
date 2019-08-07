class CreateIntercomUserJob < ApplicationJob
  queue_as :low

  ### SIDEKIQED

  def perform(user_id)
    return if Rails.env.development? && !ENV['DEBUG_INTERCOM']

    begin
      user = User.find(user_id)
    rescue
      return
    end

    intercom_api = Intercom::Client.new(token: ENV['INTERCOM_ACCESS_TOKEN'], handle_rate_limit: true)

    intercom_user = intercom_api.users.create(
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
    )
  end

end

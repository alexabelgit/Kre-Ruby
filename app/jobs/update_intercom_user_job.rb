class UpdateIntercomUserJob < ApplicationJob
  queue_as :low

  ### SIDEKIQED

  def perform(user_id, changed_fields)
    return if Rails.env.development? && !ENV['DEBUG_INTERCOM']

    begin
      user = User.find(user_id)
    rescue
      return
    end

    intercom_api = Intercom::Client.new(token: ENV['INTERCOM_ACCESS_TOKEN'], handle_rate_limit: true)

    begin
      intercom_user = intercom_api.users.find(user_id: user_id)
    rescue
      CreateIntercomUserWorker.perform_async(user_id)
      return
    end

    intercom_user.signed_up_at    = user.created_at
    intercom_user.email           = user.email
    intercom_user.name            = user.full_name
    intercom_user.last_request_at = user.current_sign_in_at
    intercom_user.last_seen_ip    = user.current_sign_in_ip.to_s
    intercom_user.phone           = user.store.phone             if user.store.present?

    intercom_user.custom_attributes['sign_in_count']      = user.sign_in_count
    intercom_user.custom_attributes['current_sign_in_at'] = user.current_sign_in_at
    intercom_user.custom_attributes['current_sign_in_ip'] = user.current_sign_in_ip.to_s
    intercom_user.custom_attributes['facebook_connected'] = user.facebook_connected?
    intercom_user.custom_attributes['twitter_connected']  = user.twitter_connected?
    intercom_user.custom_attributes['deactivated_at']     = user.deleted_at
    intercom_user.custom_attributes['last_sign_in_at']    = user.last_sign_in_at
    intercom_user.custom_attributes['last_sign_in_ip']    = user.last_sign_in_ip.to_s

    intercom_api.users.save(intercom_user)

  end

end

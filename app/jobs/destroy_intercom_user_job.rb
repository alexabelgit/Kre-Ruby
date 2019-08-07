class DestroyIntercomUserJob < ApplicationJob
  queue_as :low

  ### SIDEKIQED

  def perform(user_id)

    return if Rails.env.development?

    intercom_api = Intercom::Client.new(token: ENV['INTERCOM_ACCESS_TOKEN'], handle_rate_limit: true)

    begin
      intercom_user = intercom_api.users.find(user_id: user_id)
    rescue
      return
    end

    intercom_user.custom_attributes['deleted'] = 'Yes'
    intercom_api.users.save(intercom_user)

  end

end

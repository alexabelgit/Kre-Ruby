class UpdateIntercomUserWorker
  include Intercomable
  include Sidekiq::Worker
  sidekiq_options queue: :low, retry: 3

  def perform(user_id)
    return if skip_intercom?

    user = User.find_by id: user_id
    return if user.blank?

    begin
      intercom_user = intercom_api.users.find(user_id: user_id)
    rescue
      CreateIntercomUserWorker.perform_async(user_id)
      return
    end

    intercom_user = IntercomUser.new(intercom_user).update(user)
    intercom_api.users.save(intercom_user)
  end
end

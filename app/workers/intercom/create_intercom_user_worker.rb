class CreateIntercomUserWorker
  include Intercomable
  include Sidekiq::Worker
  sidekiq_options queue: :low, retry: 3

  def perform(user_id)
    return if skip_intercom?

    user = User.find_by id: user_id
    return if user.blank?

    intercom_api.users.create IntercomUser.build_params(user)
    CreateIntercomCompanyWorker.perform_async(user.store.id) if user.store.present?
  end
end

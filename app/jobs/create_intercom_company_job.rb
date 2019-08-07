class CreateIntercomCompanyJob < ApplicationJob
  queue_as :low

  ### SIDEKIQED

  def perform(store_id)
    return if Rails.env.development? && !ENV['DEBUG_INTERCOM']

    store = Store.find_by id: store_id
    return if store.blank?

    intercom_api = Intercom::Client.new(token: intercom_access_token, handle_rate_limit: true)

    begin
      intercom_user = intercom_api.users.find(user_id: store.user.id)
    rescue
      CreateIntercomUserWorker.perform_async(store.user.id)
      return
    end

    intercom_user.companies = [ IntercomCompany.build_params(store) ]
    intercom_user.phone = store.phone
    intercom_api.users.save(intercom_user)
  end

  private

  def intercom_access_token
    ENV['INTERCOM_ACCESS_TOKEN']
  end
end

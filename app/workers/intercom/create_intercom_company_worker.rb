class CreateIntercomCompanyWorker
  include Intercomable
  include Sidekiq::Worker
  sidekiq_options queue: :low, retry: 3

  def perform(store_id)
    return if skip_intercom?

    store = Store.find_by id: store_id
    return if store.blank?

    begin
      intercom_user = intercom_api.users.find(user_id: store.user_id)
    rescue
      CreateIntercomUserWorker.perform_async(store.user_id)
      return
    end

    if intercom_user.companies.present?
      ids = intercom_user.companies.map{|c| c.company_id}
      return if ids.include?(store.id.to_s)
    end

    intercom_user.companies = [IntercomCompany.build_params(store)]
    intercom_user.phone = store.phone
    intercom_api.users.save(intercom_user)
  end
end

class UpdateIntercomCompanyJob < ApplicationJob
  queue_as :low

  ### SIDEKIQED

  def perform(store_id)
    return if Rails.env.development? && !ENV['DEBUG_INTERCOM']

    store = Store.find_by id: store_id
    return if store.blank?

    intercom_api = Intercom::Client.new(token: intercom_access_token, handle_rate_limit: true)

    begin
      intercom_company = intercom_api.companies.find(company_id: store_id)
    rescue
      store.settings(:background_workers).update_attributes(intercom_sync_scheduled: false)
      CreateIntercomCompanyWorker.perform_async(store_id)
      return
    end

    company = IntercomCompany.new(intercom_company).update(store)
    intercom_api.companies.save(company)

    store.settings(:background_workers).update_attributes(intercom_sync_scheduled: false)
  end

  private

  def intercom_access_token
    ENV['INTERCOM_ACCESS_TOKEN']
  end
end

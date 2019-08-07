class DestroyIntercomCompanyWorker
  include Sidekiq::Worker
  sidekiq_options queue: :low, retry: 3

  def perform(store_id)
    return if Rails.env.development?

    intercom_api = Intercom::Client.new(token: ENV['INTERCOM_ACCESS_TOKEN'], handle_rate_limit: true)

    begin
      intercom_company = intercom_api.companies.find(company_id: store_id)
    rescue
      return
    end

    intercom_company.custom_attributes['deleted'] = 'Yes'
    intercom_api.companies.save(intercom_company)
  end
end

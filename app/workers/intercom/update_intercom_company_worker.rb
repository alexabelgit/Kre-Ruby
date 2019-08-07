class UpdateIntercomCompanyWorker
  include Intercomable
  include Sidekiq::Worker
  sidekiq_options queue: :low, retry: 3

  def perform(store_id)
    return if skip_intercom?

    store = Store.find_by id: store_id
    return if store.blank?

    begin
      intercom_company = intercom_api.companies.find(company_id: store_id)
    rescue
      mark_sync_as_executed(store)
      CreateIntercomCompanyWorker.perform_async(store_id)
      return
    end

    company = IntercomCompany.new(intercom_company).update(store)
    intercom_api.companies.save(company)
    mark_sync_as_executed store
  end

  private

  def mark_sync_as_executed(store)
    Store.no_touching do
      store.update_settings :background_workers, intercom_sync_scheduled: false
    end
  end
end

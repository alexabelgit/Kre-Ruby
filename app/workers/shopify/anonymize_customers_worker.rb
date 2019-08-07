class AnonymizeCustomersWorker
  include Sidekiq::Worker
  sidekiq_options queue: :low, retry: 3

  def perform(store_id, customer_id = nil)
    store = Store.find_by id_from_provider: store_id
    return if store.blank?

    Stores::AnonymizeStore.run store: store, customer_ids: Array.wrap(customer_id)
  end
end

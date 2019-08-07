class AnonymizeShopifyCustomersJob < ApplicationJob
  queue_as :low

  ### SIDEKIQED

  def perform(store_id, customer_id = nil)
    store = Store.shopify.find_by id_from_provider: store_id
    return unless store.present?

    Stores::AnonymizeStore.run store: store, customer_ids: Array.wrap(customer_id)
  end
end

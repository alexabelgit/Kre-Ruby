class MarketingPreferencesWorker
  include Sidekiq::Worker

  sidekiq_options queue: :default, retry: 5

  include Sidekiq::Throttled::Worker
  sidekiq_throttle_as :shopify_api

  def perform(store_id, customer_id, value)
      store = Store.find_by id: store_id
      return unless store.present?

      customer = Customer.find_by id: customer_id
      return unless customer.present? && customer.id_from_provider.present?

      Sync::ShopifyService.new(store: store).update_customer customer.id_from_provider, {accepts_marketing: value}
  end
end
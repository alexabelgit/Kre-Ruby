class SyncProductMetafieldsWorker
  include Sidekiq::Worker

  include Sidekiq::Throttled::Worker
  sidekiq_throttle_as :shopify_api

  sidekiq_options queue: :high, retry: Shopify::ApiWrapper::MAX_RETRIES

  def perform(store_id, id_from_provider)
    store = Store.find_by id: store_id
    return unless store&.shopify_sync_allowed?

    Time.zone = store.time_zone
    product = store.products.find_by id_from_provider: id_from_provider
    return if product.blank?

    Sync::ShopifyService.new(store: store).metafields(product: product)
  end
end

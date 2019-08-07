class CheckInstallationWorker
  include Sidekiq::Worker
  sidekiq_options queue: :critical, retry: 3

  include Sidekiq::Throttled::Worker
  sidekiq_throttle_as :shopify_api

  def perform(store_id)
    store = Store.find_by id: store_id
    return unless store&.shopify_sync_allowed?

    Sync::ShopifyService.new(store: store).check_embed_success
  end
end

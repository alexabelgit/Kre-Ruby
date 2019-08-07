class AfterShopifyStoreInstallWorker
  include Sidekiq::Worker

  include Sidekiq::Throttled::Worker
  sidekiq_throttle_as :shopify_api

  sidekiq_options queue: :critical, retry: 5

  def perform(store_id)
    store = Store.find_by id: store_id
    return unless store&.shopify_sync_allowed?

    sync_shopify_store(store) if store.shopify?
  end

  def sync_shopify_store(store)
    sync_themes_and_snippets store

    SyncScriptsWorker.perform_async(store.id)
    SyncWebhooksWorker.perform_async(store.id)
    SetupThemeWorker.perform_async(store.id)

    SyncGlobalMetafieldsWorker.perform_async store.id
    SyncAllProductsMetafieldsWorker.perform_async store.id
  end

  def sync_themes_and_snippets(store)
    sync_service = Sync::ShopifyService.new(store: store)
    sync_service.themes
    sync_service.snippets
  end
end

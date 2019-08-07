class SyncThemesWorker
  include Sidekiq::Worker
  sidekiq_options queue: :critical, retry: Shopify::ApiWrapper::MAX_RETRIES

  include Sidekiq::Throttled::Worker
  sidekiq_throttle_as :shopify_api

  def perform(store_id, mode = 'push_snippets')
    store = Store.find_by id: store_id
    return unless store.present?

    Time.zone = store.time_zone
    Sync::ShopifyService.new(store: store).themes
    PushSnippetsWorker.perform_async(store.id) if mode == 'push_snippets'
  end
end

module Shopify
  class SyncUnsyncedMetafieldsWorker
    include Sidekiq::Worker

    def perform
      stores = Store.shopify.with_outdated_metafields.where.not(access_token: nil).includes(bundles: :subscription)
      stores.find_each do |store|
        return unless store.live?

        ::SyncGlobalMetafieldsWorker.perform_async store.id

        store.products.with_outdated_metafields.find_each do |product|
          ::SyncProductMetafieldsWorker.perform_async store.id, product.id_from_provider
        end
      end
    end
  end
end
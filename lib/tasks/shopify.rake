namespace :shopify do

  desc 'Upload new js & css files for shopify store after deploy'
  task sync_store_assets: :environment do
    Store.shopify.active.each do |store|
      begin
        SyncThemesWorker.perform_async(store.id, 'push_snippets')
        SyncScriptsWorker.perform_async(store.id)
        SyncGlobalMetafieldsWorker.perform_async store.id
      rescue => ex
        Raven.capture_exception(ex, extra: {message: 'in sync store assets rake task', store_id: store.id, store_name: store.name, store_hashid: store.hashid})
      end
    end
  end

  task set_metafields_synced_at: :environment do
    query = 'UPDATE stores SET shopify_metafields_synced_at = updated_at WHERE stores.ecommerce_platform_id = 2'
    Store.connection.execute query

    query = 'UPDATE products SET shopify_metafields_synced_at=products.updated_at FROM stores WHERE products.store_id = stores.id AND stores.ecommerce_platform_id = 2'
    Product.connection.execute query
  end

  task sync_stores_full: :environment do
    Store.shopify.active.each do |store|
      AfterShopifyStoreInstallWorker.perform_async(store.id)
    end
  end

  task resync_global_metafields: :environment do
    stores = [Store.find(925)]
    stores.each do |store|
      Shopify::ResyncMetafieldsWorker.perform_async store.id
    end
  end

  task export_store_products: :environment do
    connection = ActiveRecord::Base.connection_pool.checkout.raw_connection
    stream = File.open('tmp/products.csv', 'a+')
    query = "COPY (
SELECT translate(lower(name), ' /-[]', '_') as handle,
name as title, 'Acme' as vendor, 'Shirts' as \"type\", true as published,
round(random() * 20) as variant_price,
translate(lower(name), ' /[]_', '-') as \"Variant SKU\",
round(random() * 100) as \"cost per item\"
FROM products
WHERE products.store_id = 750 LIMIT 200)
TO STDOUT WITH CSV DELIMITER ',' HEADER;"
    connection.copy_data query do
      while row = connection.get_copy_data
        stream.write row
      end
    end
  ensure
    stream.close
  end
end

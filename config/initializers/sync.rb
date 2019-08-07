Rails.configuration.products_sync_batch_size = ENV['PRODUCTS_SYNC_BATCH_SIZE']&.to_i || 100

dev_stores = (ENV['DEV_STORES_DOMAINS'] || '').split(',').map(&:strip)
Rails.configuration.dev_stores = dev_stores
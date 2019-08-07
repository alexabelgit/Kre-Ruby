class ShopifyWebhookWorker
  include Sidekiq::Worker

  sidekiq_options queue: :default

  def perform(store_id, data, params)
    store = Store.find store_id
    params = params.with_indifferent_access

    args = [store, data, params]
    case params[:object]
    when 'app'
      process_app_webhook *args
    when 'shop'
      process_shop_webhook *args
    when 'themes'
      process_themes_webhook *args
    when 'products'
      process_products_webhook *args
    when 'customers'
      process_customers_webhook *args
    when 'orders'
      process_orders_webhook *args
    end
  end

  def process_app_webhook(store, data, params)
    case params[:event]
    when 'uninstalled'
      Stores::UninstallStore.run store: store
    end
  end

  def process_shop_webhook(store, data, params)
    case params[:event]
    when 'update'
      Stores::ShopifyStoreUpdate.run store: store, data: data
    when 'redact'
      AnonymizeCustomersWorker.perform_async(params['shopify']['shop_id'])
    end
  end

  def process_themes_webhook(store, data, params)
    case params[:event]
    when 'publish'
      SyncThemesWorker.perform_async(store.id)
    end
  end

  def process_products_webhook(store, data, params)
    case params[:event]
    when 'create'
      SyncProductWorker.perform_uniq_in(ENV['SHOPIFY_CALLBACK_UNIQ_INTERVAL'].to_i.seconds, store.id, data['id'])
    when 'update'
      SyncProductWorker.perform_uniq_in(ENV['SHOPIFY_CALLBACK_UNIQ_INTERVAL'].to_i.seconds, store.id, data['id']) unless store.settings(:global).dismiss_product_update_webhook.to_b
    when 'delete'
      ArchiveProductWorker.perform_async store.id, data['id']
    end
  end

  def process_customers_webhook(store, data, params)
    shop_id = params['shopify']['shop_id']
    case params[:event]
    when 'data_request'
      store = Store.shopify.find_by id_from_provider: shop_id
      if store.present?
        BackMailer.data_access_request(store.id, params['shopify']['customer']['email']).deliver
      end
    when 'redact'
      AnonymizeCustomersWorker.perform_async shop_id, params['shopify']['customer']['id']
    end
  end

  def process_orders_webhook(store, data, params)
    trigger = store.settings(:reviews).trigger.to_sym
    case params[:event]
    when 'create'
      SyncOrderWorker.perform_uniq_in(ENV['SHOPIFY_CALLBACK_UNIQ_INTERVAL'].to_i.seconds, store.id, data['id']) if trigger == :placed
    when 'updated'
      SyncOrderWorker.perform_uniq_in(ENV['SHOPIFY_CALLBACK_UNIQ_INTERVAL'].to_i.seconds, store.id, data['id'])
    end
  end
end
class EcwidWebhookWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default

  def perform(data, signature)
    return unless signature_correct?(data, signature)

    store = Store.ecwid.find_by id_from_provider: data['storeId']
    return if store.blank?

    case data['eventType']
    when 'order.created', 'order.updated'
      SyncOrderWorker.perform_uniq_in ENV['ECWID_CALLBACK_UNIQ_INTERVAL'].to_i.seconds, store.id, data['entityId']
    when 'product.created'
      SyncProductWorker.perform_uniq_in ENV['ECWID_CALLBACK_UNIQ_INTERVAL'].to_i.seconds, store.id, data['entityId']
    when 'product.updated'
      return if store.settings(:global).dismiss_product_update_webhook.to_b
      SyncProductWorker.perform_uniq_in ENV['ECWID_CALLBACK_UNIQ_INTERVAL'].to_i.seconds, store.id, data['entityId']
    when 'product.deleted'
      ArchiveProductWorker.perform_async store.id, data['entityId']
    when 'application.uninstalled'
      Stores::UninstallStore.run store: store
    end
  end

  private

  def signature_correct?(data, signature)
    Integrations::Ecwid.validate_web_hook(data, signature)
  end
end

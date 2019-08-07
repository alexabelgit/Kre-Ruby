module Integrations
  class Ecwid

    def self.validate_web_hook(data, signature)
      hmac = OpenSSL::HMAC.digest('sha256', ENV['ECWID_CLIENT_SECRET'], "#{data['eventCreated']}.#{data['eventId']}")
      Base64.strict_encode64(hmac) == signature
    end

  end

  class Intercom

    def self.sync(model, changed_fields = nil)
      return unless model.present?
      case model
        when Store
          UpdateIntercomCompanyWorker.perform_in(5.minutes, model.id) unless model.settings(:background_workers).intercom_sync_scheduled
          store = Store.find_by id: model.id
          Store.no_touching do
            store.update_settings(:background_workers, intercom_sync_scheduled: true) if store.present?
          end
        when User
          UpdateIntercomUserWorker.perform_async(model.id, changed_fields)
      end
    end

  end
end

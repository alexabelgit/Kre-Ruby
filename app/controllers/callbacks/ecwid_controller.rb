module Callbacks
  class EcwidController < CallbacksController
    before_action :parse_data

    def create
      EcwidWebhookWorker.perform_async @data, request.headers['X-Ecwid-Webhook-Signature']
      head :ok
    end

    private

    def parse_data
      if request.headers['Content-Type'] == 'application/json'
        body = request.body.read
        keys = %w[entityId eventType eventCreated storeId]
        @data = keys.map { |key| [key, fetch_value(body, key)] }.to_h
      else
        @data = params.as_json
      end
    end

    def fetch_value(body, key)
      res = /\"#{key}\"\:\s\"?([\w\.]+)/.match(body)
      res.present? && res.size > 1 ? res[1] : nil
    end
  end
end

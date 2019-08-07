module Sync
  class EcwidService

    PAYMENT_STATUS = {
      awaiting_payment:   'AWAITING_PAYMENT',
      paid:               'PAID',
      cancelled:          'CANCELLED',
      refunded:           'REFUNDED',
      partially_refunded: 'PARTIALLY_REFUNDED',
      incomplete:         'INCOMPLETE'
    }

    FULFILLMENT_STATUS = {
      awaiting_processing: 'AWAITING_PROCESSING',
      processing:          'PROCESSING',
      shipped:             'SHIPPED',
      delivered:           'DELIVERED',
      will_not_deliver:    'WILL_NOT_DELIVER',
      returned:            'RETURNED',
      ready_for_pickup:    'READY_FOR_PICKUP'
    }

    STATUS_MAPPING = {
      placed:    [PAYMENT_STATUS[:awaiting_payment],
                  PAYMENT_STATUS[:paid],
                  PAYMENT_STATUS[:refunded],
                  PAYMENT_STATUS[:partially_refunded]],
      paid:      [PAYMENT_STATUS[:paid],
                  PAYMENT_STATUS[:refunded],
                  PAYMENT_STATUS[:partially_refunded]],
      shipped:   [FULFILLMENT_STATUS[:shipped],
                  FULFILLMENT_STATUS[:delivered],
                  FULFILLMENT_STATUS[:will_not_deliver],
                  FULFILLMENT_STATUS[:returned],
                  FULFILLMENT_STATUS[:ready_for_pickup]],
      delivered: [FULFILLMENT_STATUS[:delivered],
                  FULFILLMENT_STATUS[:returned]]
    }

    def initialize(store: , provider: nil)
      @store    = store
      @provider = provider || store.provider
      @api      = EcwidApi::Client.new(store.id_from_provider, store.access_token) if store&.ecwid?
    end

    def products
      api_products = @api.products.all(cleanUrls: true)
      return [] if api_products.nil?

      api_products.map(&method(:build_product_struct))
    end

    def product(**args)
      product_from_api   = args[:api_product]
      id_from_provider   = args[:id_from_provider].to_s
      product_from_api ||= @api.products.find(id_from_provider, cleanUrls: true)

      return nil unless product_from_api

      build_product_struct product_from_api
    end

    def order_id_from_providers(**args)
      date_from        = args[:date_from]
      date_to          = args[:date_to]

      api_orders(date_from, date_to).map{ |order_from_api| order_from_api.id.to_s }
    end

    def orders(**args)
      date_from        = args[:date_from]
      date_to          = args[:date_to]

      api_orders(date_from, date_to).map(&method(:build_order_struct))
    end

    def order(**args)
      order_from_api     = args[:order_from_api]
      id_from_provider   = args[:id_from_provider].to_s
      order_from_api   ||= @api.orders.find(id_from_provider)

      return DataStruct.new(success: false) unless order_from_api.present?

      build_order_struct order_from_api
    end

    def validate_order_trigger(**args)
      order_from_api = args[:order_from_api]
      result         = false

      trigger        = @store.settings(:reviews).trigger.to_sym
      if Order::STATUSES[trigger].present?
        trigger_value = STATUS_MAPPING[trigger]
        match = trigger_value.select{ |t| order_from_api['paymentStatus'] == t || order_from_api['fulfillmentStatus'] == t }
        result = match.any?
      end
      result
    end

    def customer(**args) #TODO through customer API on ecwid
      order_wrapper  = args[:order_wrapper]
      order_from_api = order_wrapper.object

      name = order_from_api.billing_person.present? ? order_from_api.billing_person.name
                                                    : order_from_api.email
      OpenStruct.new  email: order_from_api.email,
                      id_from_provider: order_from_api.email,
                      name: name
    end

    def api_orders(date_from, date_to)
      @api.orders.all createdFrom:   date_from.beginning_of_day.to_time.to_i,
                      createdTo:     date_to.end_of_day.to_time.to_i
    end

    private

    def build_order_struct(order_from_api)
      status = (order_from_api.payment_status == 'CANCELLED' ? 'cancelled' : 'active')
      product_ids = order_from_api.items.select { |x| x.product_id.positive? }.map{ |x| x.product_id.to_s }
      # If we have default store currency then we can use that instead of hardcoded currency
      OpenStruct.new currency:          order_from_api.respond_to?(:currency) ? order_from_api.currency : ENV['DEFAULT_CURRENCY'],
                     id_from_provider:  order_from_api.id.to_s,
                     item_total:        order_from_api.subtotal,
                     order_number:      order_from_api.id.to_s,
                     order_date:        order_from_api.create_date.to_datetime,
                     product_ids:       product_ids,
                     object:            order_from_api,
                     total:             (order_from_api.total.to_f - order_from_api.tax.to_f),
                     trigger_validated: validate_order_trigger(order_from_api: order_from_api),
                     status:            status ,
                     success:           true
    end

    def build_product_struct(product_from_api)
      storefront_availability = product_from_api.enabled.to_b ? 'enabled' : 'disabled'
      url = product_from_api[:url] || product_from_api.url
      skus = Array.wrap product_from_api[:sku]
      updated_at = product_from_api.updated.to_datetime
      DataStruct.new name:                    product_from_api.name,
                     image_url:               product_from_api.image_url,
                     updated_at:              updated_at,
                     image_updated_at:        nil, # ecwid API doesn't have separate updated_at field for media
                     url:                     url,
                     id_from_provider:        product_from_api.id.to_s,
                     storefront_availability: storefront_availability,
                     skus:                    skus,
                     object:                  product_from_api

    end
  end
end

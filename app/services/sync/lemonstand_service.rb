require 'ostruct'

module Sync
  class LemonstandService

    DEFAULT_SYNCED_FIELDS = {
      webhooks: %w(order_paid order_mark_paid order_created order_placed
                   order_updated order_status_updated order_deleted
                   customer_created)
    }

    ORDER_STATUS = {
      quote:     'Quote',
      placed:    'Placed',
      paid:      'Paid',
      shipped:   'Shipped',
      failed:    'Faild',
      cancelled: 'Cancelled',
      delivered: 'Delivered',
      fulfilled: 'Fulfilled'
    }

    # TODO lemonstand has dynamic statuses and we can not just match them by names,
    # we should fetch order statuses via API and make users able to choose between them manually

    STATUS_MAPPING = {
      placed:    [ORDER_STATUS[:quote],
                  ORDER_STATUS[:placed],
                  ORDER_STATUS[:paid],
                  ORDER_STATUS[:shipped]],
      paid:      [ORDER_STATUS[:paid],
                  ORDER_STATUS[:shipped]],
      shipped:   [ORDER_STATUS[:shipped],
                  ORDER_STATUS[:fulfilled],
                  ORDER_STATUS[:delivered]],
      delivered: [ORDER_STATUS[:fulfilled],
                  ORDER_STATUS[:delivered]]
    }

    def initialize(store: , provider: nil)
      @store    = store
      @provider = provider || store.provider
    end

    def api(object = nil)
      # LemonstandApi::Api.new('whiskyandgrape', ENV['LS_API_TOKEN'])
      ### do something if store && store.lemonstand?
    end

    def products
      product_wrappers = LemonstandAPI::Product.new(@store).all(embed: [:images]).map{|p|
        OpenStruct.new ({
          success:                 true,
          name:                    p.name,
          image_url:               (p.images.present? &&
                                    p.images['data'].present? &&
                                    p.images['data'].any? &&
                                    p.images['data'][0]['thumbnails'].present? &&
                                    p.images['data'][0]['thumbnails'].any? &&
                                    p.images['data'][0]['thumbnails'][0]['location'].present?) ? 'https:' + p.images['data'][0]['thumbnails'][0]['location'] : nil,
          url:                     "http://#{@store.domain}/product/#{p.url_name}",
          storefront_availability: p.enabled.to_b ? 'enabled' : 'disabled',
          id_from_provider:        p.id.to_s,
          object:                  p
        })}
      product_wrappers
    end

    def product(**args)
      product_from_api   = args[:product_from_api]
      id_from_provider   = args[:id_from_provider].to_s
      product_from_api ||= LemonstandAPI::Product.new(@store).find(id_from_provider, embed: [:images])

      OpenStruct.new ({
        success:                 product_from_api.present?,
        name:                    product_from_api.name,
        image_url:               (product_from_api.images.present? &&
                                  product_from_api.images['data'].present? &&
                                  product_from_api.images['data'].any? &&
                                  product_from_api.images['data'][0]['thumbnails'].present? &&
                                  product_from_api.images['data'][0]['thumbnails'].any? &&
                                  product_from_api.images['data'][0]['thumbnails'][0]['location'].present?) ? 'https:' + product_from_api.images['data'][0]['thumbnails'][0]['location'] : nil,
        url:                     "http://#{@store.domain}/product/#{product_from_api.url_name}",
        storefront_availability: product_from_api.enabled.to_b ? 'enabled' : 'disabled',
        id_from_provider:        product_from_api.id.to_s,
        object:                  product_from_api
      })
    end

    def order_id_from_providers(**args)
      date_from        = args[:date_from]
      date_to          = args[:date_to]

      order_ids = LemonstandAPI::Order.new(@store).all()
        .select{ |order|
          order.created_at >= date_from.to_s && order.created_at <= date_to.to_s
        }.map{ |order| order.id.to_s }
      order_ids
    end

    def orders(**args)
      date_from        = args[:date_from]
      date_to          = args[:date_to]

      order_wrappers = LemonstandAPI::Order.new(@store).all(embed: [:items, :customer])
        .select{ |order|
          order.created_at >= date_from.to_s && order.created_at <= date_to.to_s
        }
        .map{ |order|
          OpenStruct.new ({
            success:           true,
            id_from_provider:  order.id.to_s,
            product_ids:       ((order.items.present? && order.items['data'].present?) ? order.items['data'].map{ |p| p['shop_product_id'].to_s} : [] ),
            order_date:        order.created_at.to_datetime,
            order_number:      order.number,
            object:            order,
            trigger_validated: self.validate_order_trigger(
                                 order_from_api: order,
                                 import:         args[:import]),
            status:            ((order.status == 'Cancelled' || order.status == 'Failed') ? 'cancelled' : 'active')
          })
        }
      order_wrappers
    end

    def order(**args)
      order_from_api     = args[:order_from_api]
      id_from_provider   = args[:id_from_provider].to_s
      order_from_api   ||= LemonstandAPI::Order.new(@store).find(id_from_provider, embed: [:items, :customer])

      OpenStruct.new ({
        success:           order_from_api.present?,
        order_number:      order_from_api.number,
        order_date:        order_from_api.created_at.to_datetime,
        id_from_provider:  order_from_api.id.to_s,
        object:            order_from_api,
        product_ids:       ((order_from_api.items.present? && order_from_api.items['data'].present?) ? order_from_api.items['data'].map{ |p| p['shop_product_id'].to_s} : [] ),
        trigger_validated: self.validate_order_trigger(
                             order_from_api: order_from_api,
                             import: args[:import]),
        status:            ((order_from_api.status == 'Cancelled' || order_from_api.status == 'Failed') ? 'cancelled' : 'active')
      })
    end

    def validate_order_trigger(**args)
      # import         = args[:import]
      # return true unless import

      trigger        = @store.settings(:reviews).trigger
      order_from_api = args[:order_from_api]
      result         = false

      trigger        = @store.settings(:reviews).trigger.to_sym
      if Order::STATUSES[trigger].present?
        trigger_value = STATUS_MAPPING[trigger]
        match = trigger_value.select{ |t| order_from_api.status == t }
        result = match.any?
      end

      result
    end

    def customer(**args)
      order_wrapper    = args[:order_wrapper]
      order_from_api   = order_wrapper.object
      customer         = order_from_api.customer.present? ? OpenStruct.new(order_from_api.customer['data']) : nil
      customer       ||= LemonstandAPI::Customer.new(@store).find(order_from_api.shop_customer_id)

      OpenStruct.new({
        email:            customer.email,
        id_from_provider: customer.id.to_s,
        name:             "#{customer.first_name} #{customer.last_name}"
      })
    end

    def webhooks
      fields      = DEFAULT_SYNCED_FIELDS[:webhooks]
      url_helpers = Rails.application.routes.url_helpers
      host        = Rails.env.development? || Rails.env.test? ? ENV['NGROK_ADDRESS'] : "#{ENV['WEB_APP_PROTOCOL']}://#{ENV['WEB_APP_HOST']}"
      webhook_api = LemonstandAPI::Webhook.new(@store)

      webhooks    = []
      fields.each do |event|
        webhooks << webhook_api.create(
                      event: event,
                      uri:   url_helpers.callbacks_lemonstand_url(event: event, host: host),
                      enabled: 1
                    )
      end
      webhooks
    end

  end
end

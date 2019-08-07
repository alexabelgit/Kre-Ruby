module Sync
  class ShopifyService
    attr_reader :store, :api


    DEFAULT_SYNCED_FIELDS = {
      webhooks:            %w(orders/create orders/updated
                              products/create products/update products/delete
                              shop/update shop/redact app/uninstalled themes/publish),
      snippets:            %w(stars product-rating product-summary product-tabs styles)
    }.freeze

    PAYMENT_STATUS = {
      pending:            'pending',
      authorized:         'authorized',
      paid:               'paid',
      partially_paid:     'partially_paid',
      refunded:           'refunded',
      partially_refunded: 'partially_refunded',
      voided:             'voided'
    }.freeze

    FULFILLMENT_STATUS = {
      partial:   'partial',
      fulfilled: 'fulfilled'
    }.freeze

    STATUS_MAPPING = {
      placed:    [PAYMENT_STATUS[:pending],
                  PAYMENT_STATUS[:authorized],
                  PAYMENT_STATUS[:paid],
                  PAYMENT_STATUS[:partially_paid],
                  PAYMENT_STATUS[:refunded],
                  PAYMENT_STATUS[:partially_refunded]],
      paid:      [PAYMENT_STATUS[:paid],
                  PAYMENT_STATUS[:refunded],
                  PAYMENT_STATUS[:partially_refunded]],
      shipped:   [FULFILLMENT_STATUS[:partial],
                  FULFILLMENT_STATUS[:fulfilled]],
      delivered: [FULFILLMENT_STATUS[:fulfilled]]
    }.freeze

    def initialize(store: , provider: nil)
      @store    = store
      @provider = provider || store.provider
      @api = ::Shopify::ApiWrapper.new(store)
    end

    def products
      count = products_count
      return [] unless count&.positive?

      pages = count.div(250) + 1
      result = api.within_session(call_estimate: pages) do
        (1..pages).each.flat_map do |page|
          ShopifyAPI::Product.all(params: {page: page, limit: 250}).map(&method(:build_product_struct))
        end
      end
      result || []
    end

    def product(**args)
      product_from_api   = args[:api_product]
      id_from_provider   = args[:id_from_provider].to_s

      product_from_api ||= api.within_session { ShopifyAPI::Product.find id_from_provider }
      return nil unless product_from_api

      build_product_struct product_from_api
    end

    def order_id_from_providers(**args)
      date_from = args[:date_from].to_s
      date_to = (args[:date_to] + 1.day).to_s
      count = orders_count date_from, date_to

      return [] unless count&.positive?
      pages = count.div(250) + 1
      api.within_session(call_estimate: pages) do
        (1..pages).each.flat_map do |page|
          params = {
            created_at_min: date_from,
            created_at_max: date_to,
            status: :any,
            page: page,
            limit: 250,
            fields: [:id]
          }
          orders = ShopifyAPI::Order.all(params:  params)
          orders.map { |order| order.id.to_s }
        end
      end
    end

    def orders(**args)
      date_from = args[:date_from].to_s
      date_to = (args[:date_to] + 1.days).to_s
      count = orders_count date_from, date_to
      return [] unless count&.positive?

      pages = count.div(250) + 1
      api.within_session(call_estimate: pages) do
        (1..pages).each.flat_map do |page|
          params = {
            created_at_min: date_from,
            created_at_max: date_to,
            status: :any,
            page: page,
            limit: 250
          }
          orders = ShopifyAPI::Order.all params: params
          orders.map { |order| build_order_struct(order) }
        end
      end
    end

    def order(**args)
      order_from_api     = args[:order_from_api]
      id_from_provider   = args[:id_from_provider].to_s
      order_from_api   ||= api.within_session { ShopifyAPI::Order.find id_from_provider }

      return OpenStruct.new(success: false) unless order_from_api.present?

      build_order_struct order_from_api
    end

    def validate_order_trigger(**args)
      order_from_api = args[:order_from_api]
      result         = false
      trigger        = @store.settings(:reviews).trigger.to_sym

      if Order::STATUSES[trigger].present?
        trigger_value = STATUS_MAPPING[trigger]
        match         = trigger_value.select{ |t| order_from_api.financial_status == t || order_from_api.fulfillment_status == t }
        result        = match.any?
      end

      result
    end

    def customer(**args)
      order_wrapper  = args[:order_wrapper]
      order_from_api = order_wrapper.object
      return nil unless order_from_api.respond_to?(:customer)
      customer       = order_from_api.customer

      full_name = "#{customer.first_name} #{customer.last_name}"
      OpenStruct.new email:            customer.email,
                     id_from_provider: customer.id.to_s,
                     name: full_name
    end

    def update_customer(customer_id_from_provider, attributes)
      api.within_session do
        shopify_customer = ShopifyAPI::Customer.find customer_id_from_provider
        return unless shopify_customer.present?
        shopify_customer.update_attributes attributes
      end
    end

    def scripts
      # estimate is 2 since we usually have one tag to destroy
      api.within_session(call_estimate: 2) do
        scripts = ShopifyAPI::ScriptTag.all
        scripts.each(&:destroy)
      end
      script_url = ActionController::Base.helpers.asset_url('integrations/shopify/front.js')
      script_url = "#{ENV['NGROK_ADDRESS']}#{script_url}" if Rails.env.development?
      api.within_session do
        ShopifyAPI::ScriptTag.create event: 'onload', src: script_url
      end
    end

    def webhooks
      fields      = arrayfy_default_param(type: :webhooks)
      url_helpers = Rails.application.routes.url_helpers
      host        = Rails.configuration.urls_config.app_url

      api.within_session(call_estimate: fields.count) do
        fields.map do |topic|
          object, event = topic.split '/'
          address = url_helpers.callbacks_shopify_url(object: object, event: event, host: host)
          ShopifyAPI::Webhook.create topic: topic, address: address, format: :json
        end
      end
    end

    def metafields(product:)
      ShopifyProductMetafields.new(product).sync
    end

    def global_metafields
      ShopifyGlobalMetafields.new(store).sync
    end

    def snippets(mode: :create, theme_id: nil)
      theme_id ||= @store.settings(:shopify).theme_id || themes
      fields     = arrayfy_default_param(param: fields, type: :snippets)
      api.within_session(call_estimate: fields.count) do
        fields.map do |snippet|
          snippet_key = "snippets/hc-#{snippet}.liquid"
          case mode
          when :create
            hc_snippet = ApplicationController.render template: "integrations/shopify/#{snippet_key}",
                                                      locals: {   lang: store.settings(:global).locale },
                                                      layout:   nil

            ShopifyAPI::Asset.create theme_id: theme_id,
                                     key:      snippet_key,
                                     value:    hc_snippet
          when :delete
            begin
              asset = ShopifyAPI::Asset.find snippet_key,
                                             params: { theme_id: theme_id }
              asset.destroy if asset
            rescue ActiveResource::ResourceNotFound => ex
            end
          end
        end
      end
    end

    def themes
      main_theme = nil
      api.within_session do
        main_theme = ShopifyAPI::Theme.all.select { |t| t.role == 'main' }.first
      end
      return unless main_theme
      store.update_settings(:shopify, theme_id: main_theme.id, theme_name: main_theme.name, auto_inject_failed: false)
      check_widget_usage
      main_theme.id
    end

    def setup_theme
      snippets
      inject_code
    end

    def inject_code
      return unless ::Shopify::Utils.auto_inject_supported?(store: store)

      theme_name     = store.settings(:shopify).theme_name
      theme_id       = store.settings(:shopify).theme_id

      current_config = ::Shopify::Utils.get_theme_config(theme_name: theme_name)
      return unless current_config

      store.update_settings(:shopify, auto_inject_steps_remaining: current_config.count)

      api.within_session(call_estimate: current_config.size * 2) do
        current_config.each do |injection|
          injection.symbolize_keys!
          asset = ShopifyAPI::Asset.find injection[:asset], params: { theme_id: theme_id }
          content = asset.value

          unless content.include?(injection[:code])
            injection_result = Shopify::Utils.perform_injection(injection: injection, content: content)
            if injection_result[:content].include?(injection_result[:replacement])
              ShopifyAPI::Asset.create theme_id: theme_id,
                                       key: injection[:asset],
                                       value: injection_result[:content]
            else
              store.update_settings(:shopify, auto_inject_failed: true)
            end
          end
          check_widget_usage(injection[:widget]) if injection[:widget].present?
          auto_inject_steps_remaining = store.reload.settings(:shopify).auto_inject_steps_remaining
          store.update_settings(:shopify, auto_inject_steps_remaining: auto_inject_steps_remaining - 1)
        end
      end
    ensure
      store.update_settings(:shopify, auto_inject_try_performed: true)
      broadcast role: 'auto-inject-reload', code: 'location.reload();'
    end


    def auto_remove
      store.update_settings(:shopify, auto_remove_status: '')
      themes = api.within_session do
        ShopifyAPI::Theme.all.select { |x| Shopify::Utils.auto_inject_supported?(name: x.name) }
      end

      themes.each do |theme|
        current_config = Shopify::Utils.get_theme_config(theme_name: theme.name)
        current_config.each do |injection|
          remove_code(theme_name: theme.name, theme_id: theme.id, injection_id: injection['id'])
        end
        snippets(mode: :delete, theme_id: theme.id)
      end

      update_onboarding_settings
      broadcast role: 'auto-remove-reload', code: 'location.reload();'
    end

    def remove_code(theme_name: , theme_id: , injection_id:)
      injection   = Shopify::Utils.get_theme_config(theme_name: theme_name, injection_id: injection_id)

      api.within_session(call_estimate: 2) do
        asset = find_asset injection[:asset], theme_id
        content = asset.value
        content = Shopify::Utils.perform_removal(content: content)
        ShopifyAPI::Asset.create theme_id: theme_id,
                                 key: injection[:asset],
                                 value: content

        %w(hc-product-rating hc-product-summary hc-product-tabs hc-styles).each do |snippet|
          next unless content.include?(snippet)
          auto_remove_status = store.reload.settings(:shopify).auto_remove_status
          status = { theme: theme_name, file: injection[:asset], snippet: snippet }
          status_list = Shopify::Utils.auto_remove_status_list(store)
          unless status_list.include?(status.stringify_keys)
            store.update_settings(:shopify, auto_remove_status: "#{auto_remove_status}#{auto_remove_status == '' ? '' : ','}#{status.to_json}")
          end
        end
      end
      check_widget_usage(injection[:widget]) if injection[:widget].present?
    end

    def check_widget_usage(widgets = %w(product_rating product_summary product_tabs stylesheet))
      Array.wrap(widgets).each do |w|
        Widgets::Utils.check_in_use(store: store, handle: w)
      end
      store.update_settings(:shopify, installation_last_checked: Time.now.utc)
    end

    def check_embed_success
      check_widget_usage
      broadcast role: 'check-embed-reload', code: 'location.reload();'
    end

    def update_onboarding_settings
      stylesheet_status = store.setting_truthy? :widgets, :stylesheet_in_use
      widgets_status = store.settings_truthy? :widgets, :product_tabs_in_use, :product_rating_in_use, :product_summary_in_use

      store.update_settings :onboarding, stylesheet_embedded: stylesheet_status,
                                         widgets_embedded: widgets_status
    end

    def shop(**args)
      shop_info = args[:shop_info] || api.within_session { ShopifyAPI::Shop.current }
      if shop_info.present?
        shop_info = shop_info.attributes if shop_info.class.method_defined? :attributes

        store.update_attributes(
          url:        "https://#{shop_info['domain']}",
          phone:      shop_info['phone'],
          legal_name: shop_info['name'],
          name:       shop_info['name']
        )
        store.update_attributes(domain: shop_info['domain']) if shop_info['domain'].present? && shop_info['domain'].include?('.myshopify.com')
        store.update_settings(:global, time_zone: shop_info['iana_timezone'])
      end
      shop_info.present?
    end

    def product_exists?
      products_count.positive?
    end

    def storefront_open?
      api.within_session { !ShopifyAPI::Shop.current.password_enabled }
    end

    protected

    def broadcast(role:, code:)
      key = "shopify-#{store.user.hashid}"
      js_value = {
        indicator: "[data-role='#{role}']",
        code: code
      }
      ActionCable.server.broadcast key, js: js_value
    end

    # expects to be called within session. Estimate - 1 api call
    def find_asset(asset, theme_id)
      ShopifyAPI::Asset.find asset, params: { theme_id: theme_id }
    end

    def products_count
      count = api.within_session { ShopifyAPI::Product.count }
      count.is_a?(Integer) ? count : 0
    end

    def orders_count(date_from, date_to)
      api.within_session { ShopifyAPI::Order.count created_at_min: date_from, created_at_max: date_to, status: :any }
    end

    def build_order_struct(order)
      # If we have default store currency then we can use that instead of hardcoded currency
      OpenStruct.new currency:          order.respond_to?(:currency) ? order.currency : ENV['DEFAULT_CURRENCY'],
                     id_from_provider:  order.id.to_s,
                     item_total:        order.total_line_items_price,
                     order_number:      order.order_number,
                     order_date:        order.created_at.to_datetime,
                     product_ids:       order.line_items.map { |x| x.product_id.to_s },
                     object:            order,
                     total:             (order.total_price.to_f - order.total_tax.to_f),
                     trigger_validated: validate_order_trigger(order_from_api: order),
                     status:            (order.cancelled_at.present? ? 'cancelled' : 'active'),
                     success:           true
    end

    def build_product_struct(p)
      image = p.images.any? ? p.images.first : nil
      url = "https://#{store.domain}/products/#{p.handle}"
      storefront_availability = p.published_at.present? ? 'enabled' : 'disabled'
      skus = Array.wrap(p.variants.map(&:sku))

      image_updated_at = image.present? ? DateTime.parse(image.updated_at) : nil
      DataStruct.new name: p.title,
                     image_url: image&.src,
                     updated_at: DateTime.parse(p.updated_at),
                     image_updated_at: image_updated_at,
                     url: url,
                     storefront_availability: storefront_availability,
                     id_from_provider: p.id.to_s,
                     skus: skus,
                     object: p
    end

    def arrayfy_default_param(param: nil, type: )
       param ||= DEFAULT_SYNCED_FIELDS[type.to_sym]
       Array.wrap(param)
    end
  end
end

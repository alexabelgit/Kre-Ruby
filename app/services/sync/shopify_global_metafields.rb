module Sync
  class ShopifyGlobalMetafields
    attr_reader :store, :api
    delegate :hashid, :theme_css, :storefront_status,
             :custom_stylesheet_active, :custom_stylesheet_code, to: :store

    def initialize(store)
      @store = store
      @api = ::Shopify::ApiWrapper.new(store)
    end

    def sync
      return unless store.shopify_sync_allowed?
      
      if store.shopify_metafield_id
        update_metafields store.shopify_metafield_id
        store.update shopify_metafields_synced_at: DateTime.current
      else
        post_metafields
      end
    end

    private

    def post_metafields
      metafield = nil
      api.within_session do
        metafield = ShopifyAPI::Metafield.new metafield_json
        metafield = ShopifyAPI::Shop.current.add_metafield metafield
      end

      if metafield&.persisted?
        store.update shopify_metafield_id: metafield.id, shopify_metafields_synced_at: DateTime.current
      end
    end

    def update_metafields(metafield_id)
      api.within_session do
        metafield = ShopifyAPI::Metafield.find(metafield_id)
        metafield.value = metafield_value
        metafield.save
      end
    end

    def metafield_json
      {
        description: 'HC global metafields',
        namespace: :helpfulcrowd,
        key: :global,
        value: metafield_value,
        value_type: :json_string
      }
    end

    def metafield_value
      {
        store_id: hashid,
        easy_reviews: easy_reviews?,
        show_qa: show_qa?,
        product_summary_show_rating_chart: product_summary_show_rating_chart?,
        product_summary_enable_links: product_summary_enable_links?,
        rating_position: rating_position,
        rating_layout: rating_layout,
        summary_position: summary_position,
        theme: theme_css,
        css_url: css_url,
        locale: locale,
        storefront_status: storefront_status,
        last_updated_at: last_updated_at,
        custom_stylesheet_active: custom_stylesheet_active,
        custom_stylesheet_code: custom_stylesheet_code
      }.to_json
    end

    def easy_reviews?
      bool_to_int store.easy_reviews?
    end

    def show_qa?
      show_qa = store.questions_enabled? && store.settings(:widgets).product_summary_show_qa.to_b
      bool_to_int show_qa
    end

    def rating_position
      store.settings(:widgets).product_rating_position
    end

    def rating_layout
      store.settings(:widgets).product_rating_layout
    end

    def summary_position
      store.settings(:widgets).product_summary_position
    end

    def product_summary_show_rating_chart?
      bool_to_int store.settings(:widgets).product_summary_show_rating_chart
    end

    def product_summary_enable_links?
      bool_to_int store.settings(:widgets).product_summary_links
    end

    def bool_to_int(value)
      value&.to_b ? 1 : 0
    end

    def css_url
      css_url = ActionController::Base.helpers.asset_url('integrations/shopify/front.css')
      css_url = "#{ENV['NGROK_ADDRESS']}#{css_url}" if Rails.env.development?
      css_url
    end

    def locale
      store.settings(:global).locale
    end

    def last_updated_at
      store.updated_at
    end
  end
end

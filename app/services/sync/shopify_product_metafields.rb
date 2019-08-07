module Sync
  class ShopifyProductMetafields
    attr_reader :product, :api, :store

    def initialize(product)
      @product = product
      @store = product.store
      @api = ::Shopify::ApiWrapper.new(product.store)
    end

    def sync
      return unless store.shopify_sync_allowed?

      api_product = api.within_session { ShopifyAPI::Product.find product.id_from_provider  }

      return unless api_product # TODO: mark DB product as non-syncable as well

      if product.shopify_metafield_id
        result = update_metafields product.shopify_metafield_id
        post_metafields(api_product) if result.nil?
      else
        post_metafields api_product
      end
      product.update shopify_metafields_synced_at: DateTime.current
    end

    private

    def post_metafields(api_product)
      metafield = api.within_session(call_estimate: 2) do
        metafield = ShopifyAPI::Metafield.new metafield_json
        api_product.add_metafield metafield
      end

      product.update(shopify_metafield_id: metafield.id) if metafield&.persisted?
    end

    def update_metafields(metafield_id)
      api.within_session(call_estimate: 2) do
        metafield = ShopifyAPI::Metafield.find(metafield_id)
        return nil if metafield.nil?

        metafield.value = metafield_value
        metafield.save
      end
    end

    def metafield_json
      {
        description: 'HC product metafields',
        namespace: :helpfulcrowd,
        key: :product,
        value: metafield_value,
        value_type: :json_string
      }
    end

    def metafield_value
      {
        rating: product.rating,
        suppressed: suppressed?,
        reviews_count: reviews_count,
        qa_count: questions_count,
        rating_data: product.rating_data,
        store_hashid: product.store.hashid,
        product_hashid: product.hashid
      }.to_json
    end

    def suppressed?
      product.suppressed? ? 1 : 0
    end

    def reviews_count
      product.reviews.published.count
    end

    def questions_count
      product.questions.published.count
    end
  end
end

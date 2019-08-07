module Widgets
  class Utils

    require 'rest-client'

    HANDLES = { product_rating:       'product-rating',
                product_summary:      'product-summary',
                product_tabs:         'product-tabs',
                review_slider:        'review-slider',
                reviews_facebook_tab: '',
                sidebar:              'sidebar',
                stylesheet:           'stylesheet' }

    def self.check_in_use(store:, handle: :product_tabs)
      # TODO this can't work for all widgets.. For example, reviews_facebook_tab
      # should have a different flow so we need to rewrite this method
      handle         = handle.to_sym
      snippet_handle = HANDLES[handle.to_sym]

      if handle == :product_rating
        url = "#{store.url}/collections/all" if store.shopify? # TODO instead of writing platform based if-s here,
                                                               # we should create a universal method store.products_home_url
                                                               # or something similar that works for all platforms and returns
                                                               # store.url as a fallback
      elsif handle == :stylesheet
        url = store.url if store.shopify? # TODO this should work on all platforms but won't work
                                          # for Ecwid if it's a wix site, or if store uses non-ecwid homepage
      else
        published_product = store.products.enabled_on_site.unsuppressed.first
        url               = published_product.url if published_product.present?
      end

      result = false

      if url.present?
        begin
          response = RestClient.get(URI::encode(url))
          result   = response.code == 200 && response.body.include?("data-hc=\"#{snippet_handle}\"")
        rescue
          # This is to make sure that result remains false if RestClient.get(url)
          # fails and that check_in_use does not throw an error
        end
      end

      store.settings(:widgets).update_attributes("#{handle}_in_use": result)
      result
    end

  end
end

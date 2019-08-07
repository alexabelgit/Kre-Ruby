HC_JS.ecwid.rating = {
  product_page: function (page){
    var ecwidFeatureToggles = Ecwid.getFeatureToggles();
    var container = jQuery('.ec-store__product-page .product-details__product-title[itemprop="name"]');

    // use legacy container in case newProductsListing is not enabled
    if (!ecwidFeatureToggles['newProductList']) {
      container = jQuery('.ecwid-productBrowser-ProductPage .ecwid-productBrowser-detailsContainer .ecwid-productBrowser-head');
    }

    if (!container.is(':visible')) {
      container.html('').css('display', 'block');
    }
    HC_JS.helpers.init_summary_container(container, page.productId, 'child');

    jQuery.get(HC_JS.routes.front_product_summary_url(Ecwid.getOwnerId(), page.productId, {
      format: 'js'
    }), function (js) {
      eval(js);
    });
  },
  lists: function (page, data){
    this.old_list(page, data);
    this.new_list(page, data);
  },
  old_list: function (page, data){
      var page_type = page.type.toLowerCase();
      var id_container_prefix = 'ecwid-product-id-';
      var store_id = Ecwid.getOwnerId();
      jQuery('[class^="' + id_container_prefix + '"],[class*="' + id_container_prefix + '"]').each(function (){
          var container = jQuery(this);
          var product_ids = jQuery.grep(container.attr('class').split(/\s+/), function(n) {
              return n.indexOf(id_container_prefix) > -1;
          });
          product_ids = product_ids.map(function (n){
              return n.replace(id_container_prefix, '');
          });
          var name_container = container.find('.ecwid-productBrowser-productNameLink');
          jQuery.each(product_ids, function (index, value) {
              var productId = value;
              if (HC_JS.helpers.hc_check_on_suppression(productId, data.suppressions)) {
                  container.find('[data-hc="product-rating"]').remove();
                  HC_JS.helpers.init_rating_container(name_container, productId, 'child');
                  jQuery.get(HC_JS.routes.front_product_rating_url(store_id, productId, {
                      format: 'js'
                  }), function (js) {
                      eval(js);

                      if (page_type != 'category') {
                          var ecwid_wrapper_bottom_div = name_container.parents('.ecwid-productBrowser-relatedProducts-item-bottom').first();
                          if (!ecwid_wrapper_bottom_div.attr('data-hc-height-corrected')) {
                              var processed_sibling = ecwid_wrapper_bottom_div.siblings('[data-hc-height-corrected="true"]');
                              if (processed_sibling.length > 0)
                                  ecwid_wrapper_bottom_div.css('height', processed_sibling.first().css('height'));
                              else
                                  ecwid_wrapper_bottom_div.css('height', parseInt(ecwid_wrapper_bottom_div.css('height')) + 15 + 'px');
                              ecwid_wrapper_bottom_div.attr('data-hc-height-corrected', true);
                          }
                          var ecwid_wrapper_div = ecwid_wrapper_bottom_div.parents('div').first();
                          if (!ecwid_wrapper_div.attr('data-hc-height-corrected')) {
                              ecwid_wrapper_div.css('height', parseInt(ecwid_wrapper_div.css('height')) + 15 + 'px');
                              ecwid_wrapper_div.attr('data-hc-height-corrected', true);
                          }
                      }
                  });
              }
          });
      });
  },
  new_list: function(page, data){
      var store_id = Ecwid.getOwnerId();
      jQuery('.grid__products a.grid-product__title').each(function (){
          var title_container = jQuery(this);
          var href = title_container.attr('href');
          var product_id = false;
          if (href.indexOf('/p/') >= 0) {
            product_id = href.split('/p/').pop().split('/').shift();
          } else if (href.indexOf('-p') >= 0) {
            product_id = href.split('-p').pop();
          }
          product_id = product_id.split('&')[0];
          if (product_id && HC_JS.helpers.hc_check_on_suppression(product_id, data.suppressions)) {
              HC_JS.helpers.init_rating_container(title_container, product_id, 'child');
              jQuery.get(HC_JS.routes.front_product_rating_url(store_id, product_id, {
                  format: 'js'
              }), function (js) {
                  eval(js);
              });
          }
      });
  },
  bind_slider_events: function (page, data){
      //TODO Double request
      var handler = function(e) {
          setTimeout(function () {
              HC_JS.ecwid.rating.old_list(page, data);
          }, 300);
          jQuery(this).one('click', handler);
      };
      var related_products_button = jQuery('td.ecwid-productBrowser-relatedProducts-button');

      related_products_button.one('click', handler);
  },
  init: function(page, data){
      var page_type = page.type.toLowerCase();
      //Product Page
      if (page_type == 'product' && data.widgets.product_summary)
          this.product_page(page);
      if (data.widgets.product_rating){
        //Old lists
        this.old_list(page, data);
        //New lists
        if (page_type != 'product')
            this.new_list(page, data);
        //Bind Related Product change on slider
        this.bind_slider_events(page, data);
      }
  }
};

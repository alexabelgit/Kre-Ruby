jQuery(document).ready(function() {
    HC_JS.helpers.ajax_setup();
    HC_JS.helpers.init_hc_local_storage();
    jQuery('[data-hc]').hc_scroll_to();
    jQuery('[data-hc="product-tabs"][data-hc-id]').each(function () {
        var tabs_container = jQuery(this);
        var store_id       = tabs_container.attr('data-hc-store-id');
        var product_id     = tabs_container.attr('data-hc-id');
        jQuery.get(HC_JS.routes.front_product_tabs_url(store_id, product_id, {format: 'js'}), function (js) {
            if (jQuery('#hc-product-tabs').length <= 0)
              eval(js);
            tabs_container.hc_scroll_to();
        });
        jQuery.get(HC_JS.routes.front_product_ld_json_url(store_id, product_id, {format: 'js'}), function (js) {
          if (jQuery('[data-hc="ld-json"]').length <= 0)
            eval(js);
        });
    });

    // Remotify the product ratings chart in the product summary hover section
    jQuery('[data-hc="product-summary"] [data-remotify="true"]').each(function () {
      jQuery(this).remotify();
    });
});

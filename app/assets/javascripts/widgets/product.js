HC_JS.widgets.product_tabs = {
  init: function (data_object, container){
    if (!container)
      container = jQuery(document);

    HC_JS.helpers.init_tabs_container(data_object.product_id, container);
    jQuery.get(HC_JS.routes.front_product_tabs_url(data_object.store_id, data_object.product_id, {format: 'js'}), function (js) {
      if (jQuery('[data-hc="product-tabs"][data-hc-id="' + data_object.product_id + '"] [data-role="tabs"][data-id="' + data_object.product_id + '"]').length <= 0) {
        eval(js);
        if (typeof data_object.theme !== "undefined")
          HC_JS.helpers.hc_force_theme(data_object.theme);
      }
    });
  }
};

HC_JS.widgets.json_ld = {
  init: function (data_object){
    jQuery.get(HC_JS.routes.front_product_ld_json_url(data_object.store_id, data_object.product_id, {
      format: 'js'
    }), function (js) {
      eval(js);
    });
  }
};

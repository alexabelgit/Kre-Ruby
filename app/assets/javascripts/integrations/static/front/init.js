function hc_process_static_page(store_id, theme, widgets) {
  //Query('[data-hc]').remove();
  HC_JS.helpers.ajax_setup();
  HC_JS.helpers.init_hc_local_storage();
  widgets = widgets.split(',');
  for (var i = 0; i < widgets.length; i++) {
    var widget = widgets[i];
    switch(widget) {
      case 'sidebar':
        HC_JS.widgets.sidebar.init(store_id);
        break;
      case 'review_journal':
        HC_JS.widgets.review_journal.init(store_id);
        break;
      case 'review_slider':
        HC_JS.widgets.review_slider.init(store_id);
        break;
      case 'product_tabs':
        var product_id = jQuery('[data-hc="product-tabs"]').attr('data-hc-id');
        if (product_id){
          jQuery.get(HC_JS.routes.front_product_ld_json_url(store_id, product_id, {
            format: 'js'
          }), function (js) {
            if (jQuery('[data-hc="ld-json"]').length <= 0)
              eval(js);
          });
          jQuery.get(HC_JS.routes.front_product_tabs_url(store_id, product_id, {format: 'js'}), function (js) {
            if (jQuery('[data-hc="product-tabs"][data-hc-id="' + product_id + '"] div').length <= 0)
              eval(js);
          });
        }
        break;
        case 'product_rating':
          jQuery('[data-hc="product-rating"]').each(function (){
            var rating_container = jQuery(this);
            var product_id = rating_container.attr('data-hc-id');
            jQuery.get(HC_JS.routes.front_product_rating_url(store_id, product_id, {
                format: 'js'
            }), function (js) {
                if (rating_container.find('div').length <= 0)
                  eval(js);
            });
          });
          break;
      case 'product_summary':
        var product_id = jQuery('[data-hc="product-summary"]').attr('data-hc-id');
        if (product_id){
          jQuery.get(HC_JS.routes.front_product_summary_url(store_id, product_id, {
              format: 'js'
          }), function (js) {
            if (jQuery('[data-hc="product-summary"][data-hc-id="' + product_id + '"] div').length <= 0)
              eval(js);
          });
        }
        break;
      default:
        console.log('HC: unknown widget "' + widget + '"');
    }
  }
  jQuery('.hc-widget > div').addClass(theme);
}

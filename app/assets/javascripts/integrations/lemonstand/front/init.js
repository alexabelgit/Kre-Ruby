function hc_init(data){
  var store_id        = data.store_id;
  var theme           = data.theme;
  var product_id      = undefined;

  var product_summary = jQuery('[data-hc="product-summary"]');
  if(product_summary) {
    product_id = product_summary.attr('data-hc-id');
    if(product_id){
      if (HC_JS.helpers.hc_check_on_suppression(product_id, data.suppressions)){
        HC_JS.widgets.product_summary.init({product_id: product_id, store_id: store_id, theme: theme});
      }
    }
  }
  
  var product_tabs = jQuery('[data-hc="product-tabs"]');
  if(product_tabs) {
    product_id = product_tabs.attr('data-hc-id');
    if(product_id){
      if (HC_JS.helpers.hc_check_on_suppression(product_id, data.suppressions)){
        HC_JS.widgets.product_tabs.init({product_id: product_id, store_id: store_id, theme: theme});
      }
    }
  }

  var product_ratings = jQuery('[data-hc="product-rating"]');
  product_ratings.each(function(index) {
    product_id = this.attributes['data-hc-id'].value;
    if(product_id){
      if (HC_JS.helpers.hc_check_on_suppression(product_id, data.suppressions)){
        HC_JS.widgets.product_rating.init({product_id: product_id, store_id: store_id, theme: theme});
      }
    }
  });

}

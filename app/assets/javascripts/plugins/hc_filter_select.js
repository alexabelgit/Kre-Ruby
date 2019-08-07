jQuery.fn.hc_filter_select = function() {
  var item = jQuery(this);
  if (!item.is('select[data-hc="sort"]'))
    item = item.find('select[data-hc="sort"]');
  item.on('change', function () {
    var select = jQuery(this);
    jQuery.get(HC_JS.routes.front_product_reviews_url({ sort:       select.val(),
                                                        store_id:   select.attr('data-store-id'),
                                                        product_id: select.attr('data-product-id'),
                                                        format:     'js' }), function (js) {} );
  });
  return this;
};

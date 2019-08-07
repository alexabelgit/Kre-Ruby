jQuery.fn.coupon_select = function() {
  var item = jQuery(this);
  if (!item.is('select[data-hc="coupon-select"]'))
    item = item.find('select[data-hc="coupon-select"]');
  item.on('change', function () {
    var select = jQuery(this);
    jQuery.get(HC_JS.routes.template_back_discount_coupon_path({ id: ((!select.val()) ? 'NULL' : select.val()),
                                                                 format:    'js' }), function (js) {} );
  });
  return this;
};

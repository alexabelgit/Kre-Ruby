jQuery.fn.tabify = function() {
  var item = jQuery(this);
  if (!item.is('[data-role="tabs"]'))
    item = item.find('[data-role="tabs"]');
  item.find('[data-role="header"] [data-tab="true"]').click(function (e) {
    var that = jQuery(this);
    that.siblings('[data-tab="true"]').removeClass('hc-product-tab--active');
    that.addClass('hc-product-tab--active');
    var active_tab = item.find('[data-role="tabs-container"] [data-role="' + that.attr('data-role') + '"]');
    active_tab.siblings().hide();
    active_tab.show();
    item.find('[data-role="tabs-container"]').scrollTop(0);
    e.preventDefault();
  });
  this.find('[data-role="header"] a').first().trigger('click');
  return this;
};

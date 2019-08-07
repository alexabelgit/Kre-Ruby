jQuery.fn.hc_display_name = function() {
  jQuery(this).find('[data-hc="display-name-text-field"]').each(function (){
    var item = jQuery(this);
    var form = item.parents('form').first();
    item.change(function (){
      jQuery.get(HC_JS.routes.display_name_front_plugins_url(item.attr('data-hc-id'), {
        name: item.val(),
        form_id: form.attr('id'),
        format: 'js'
      }), function (js) {
        eval(js);
      });
    });

  });
  return this;
};

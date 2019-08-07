HC_JS.widgets.review_slider = {
  init: function (store_id){
    HC_JS.helpers.init_review_slider_widget(jQuery('body'));
    jQuery.get(HC_JS.routes.review_slider_front_widgets_url({ store_id: store_id, format: 'js' }),
    function (js){
      eval(js);
      jQuery('body').hc_review_slider_scroll();
    });
  }
};

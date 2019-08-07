HC_JS.widgets.sidebar = {
  init: function (store_id){
    HC_JS.helpers.init_sidebar_widget(jQuery('body'));
    jQuery.get(HC_JS.routes.sidebar_front_widgets_url({store_id: store_id, format: 'js'}),
    function (js){
      eval(js);
    });
  }
};

HC_JS.widgets.review_journal = {
  init: function (store_id){
    HC_JS.helpers.init_review_journal_widget(jQuery('body'));
    jQuery.get(HC_JS.routes.review_journal_front_widgets_url({store_id: store_id, format: 'js'}),
    function (js){
      eval(js);
    });
  }
};

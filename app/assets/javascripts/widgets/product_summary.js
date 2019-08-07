HC_JS.widgets.product_summary = {
    init: function (data_object, container){
        if (!container)
            container = jQuery(document);
        HC_JS.helpers.init_summary_container(container, data_object.product_id, 'child');
        jQuery.get(HC_JS.routes.front_product_summary_url(data_object.store_id, data_object.product_id, {
            format: 'js'
        }), function (js) {
            eval(js);
            HC_JS.helpers.hc_force_theme(data_object.theme);
        });
    }
};

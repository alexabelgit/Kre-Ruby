function hc_process_page_type(page, data) {
    jQuery('[data-hc]').remove();
    HC_JS.helpers.ajax_setup();
    HC_JS.helpers.init_hc_local_storage();
    if (data.widgets.sidebar)
        HC_JS.widgets.sidebar.init(Ecwid.getOwnerId());
    switch (page.type)
    {
        case 'PRODUCT':
            if (HC_JS.helpers.hc_check_on_suppression(page.productId, data.suppressions)) {
                HC_JS.ecwid.rating.init(page, data);
                var product_data = {store_id: Ecwid.getOwnerId(), product_id: page.productId}
                HC_JS.widgets.json_ld.init(product_data);
                if (data.widgets.product_tabs)
                  HC_JS.widgets.product_tabs.init(product_data, jQuery('.ecwid-productBrowser-ProductPage-' + page.productId));
            }
            break;
        case 'CATEGORY':
        case 'SEARCH':
            HC_JS.ecwid.rating.init(page, data);
            break;
        case 'CART':
            if (data.widgets.product_rating){
              setTimeout(function () {
                  HC_JS.ecwid.rating.lists(page, data);
                  HC_JS.ecwid.rating.bind_slider_events(page, data);
              }, 2500);
            }
            break;
        case 'ORDERS':
            break;
    }
    jQuery('.hc-widget > div').addClass(data.css.theme);
}

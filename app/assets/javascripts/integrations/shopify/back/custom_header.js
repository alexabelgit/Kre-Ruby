document.addEventListener("turbolinks:request-start", function(event) {
  var xhr = event.data.xhr;
  xhr.setRequestHeader("X-Shopify-Domain", jQuery('body').attr('data-shopify-domain'));
});

jQuery(document).on('turbolinks:request-end',  function() {
  if (event.data.xhr.status == 401 || event.data.xhr.status == 422){
    hc_shopify_login_again_if_different_shop_modal();
    //hc_full_page_redirect();
  }
});

jQuery.ajaxSetup({
  statusCode: {
    401: function(){
      hc_shopify_login_again_if_different_shop_modal();
    },
    422: function(){
      hc_shopify_login_again_if_different_shop_modal();
    }
  }
});

jQuery(document).on('turbolinks:load', function() {
  var shopify_domain = jQuery('[data-shopify-domain]').attr('data-shopify-domain');
  jQuery('[data-shopify-domain] a,[data-shopify-domain] form').each(function (){
    var object = jQuery(this);
    var attr = object.is('form') ? 'action' : 'href';
    var href = object.attr(attr);
    if (href.indexOf('?') !== -1){
      object.attr(attr, href + '&shopify_store_domain=' + shopify_domain);
    } else {
      object.attr(attr, href + '?shopify_store_domain=' + shopify_domain);
    }
  });
});

function hc_shopify_login_again_if_different_shop_modal(){
  ShopifyApp.Modal.alert({
    title: "Please sign in",
    message: "Looks like you have signed out from your HelpfulCrowd account. We may have failed to process your last request so please check and repeat the action if needed. Close this window to sign in again.",
    okButton: "Sign in"
  }, function(result){
    window.location.replace(HC_JS.routes.new_oauth_shopify_session_url({shop: jQuery('[data-shopify-domain]').attr('data-shopify-domain'), iframe: true}));
  });
}

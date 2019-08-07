document.addEventListener("DOMContentLoaded", function() {
  hc_full_page_redirect();
});

jQuery(document).on('turbolinks:load', function() {
  hc_full_page_redirect();
});

function hc_full_page_redirect(){
  var redirectTargetElement = document.getElementById("redirection-target");
  if (redirectTargetElement != null){
    var targetInfo = JSON.parse(redirectTargetElement.dataset.target);
    if (window.top == window.self) {
        // If the current window is the 'parent', change the URL by setting location.href
        window.top.location.href = targetInfo.url;
    } else {
        // If the current window is the 'child', change the parent's URL with postMessage
        normalizedLink = document.createElement('a');
        normalizedLink.href = targetInfo.url;
        data = JSON.stringify({
            message: 'Shopify.API.remoteRedirect',
            data: { location: normalizedLink.href }
        });
        window.parent.postMessage(data, targetInfo.myshopifyUrl);
    }
  }
}

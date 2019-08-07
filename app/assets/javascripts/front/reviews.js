jQuery(document).on('turbolinks:load', function() {
  jQuery('[data-model="review"] form textarea[name*="feedback"][data-counterify!="initialized"]').counterify();
  jQuery('select[data-hc="sort"]').hc_filter_select();
  jQuery('body').sidify();
});

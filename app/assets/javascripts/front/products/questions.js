jQuery(document).on('turbolinks:load', function() {
  jQuery('[data-model="question"] form textarea[name*="body"][data-counterify!="initialized"]').counterify();
});

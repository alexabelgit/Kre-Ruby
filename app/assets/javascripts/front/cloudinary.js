jQuery(document).on('turbolinks:load', function() {
  jQuery(this).cloudify(jQuery('body').attr('data-lang'));
});

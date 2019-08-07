jQuery(document).on('turbolinks:load', function() {
  jQuery('.announcement__hide').click(function () {
    jQuery(this).closest('.announcement').hide();
  })
})

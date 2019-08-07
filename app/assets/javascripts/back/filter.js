jQuery(document).on('turbolinks:load', function() {
  jQuery('select[data-role="filter"]').on('change', function() {
    var data_url = jQuery(this).find(':selected').attr('data-url');
    if (data_url)
        window.location.href = data_url;
  });

  jQuery('form[data-role="filter"]').submit(function(e){
    var form     = jQuery(this);
    var data_url = form.attr('action') + '?term=' + form.find('input[type="search"][data-role="filter"]').val();
    if (data_url)
      window.location.href = data_url;
    return false;
  });
});

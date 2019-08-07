jQuery(document).on('turbolinks:load', function() {
  jQuery('.intercom-custom').on('click', function() {
    Intercom('show');
  });

  jQuery('#widget-console-link-to-manual-guide').on('click', function() {
    slide_to_anchor('#add-stylesheet-and-recommended-widgets-manually')
  });
});

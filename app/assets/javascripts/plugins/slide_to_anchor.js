function slide_to_anchor(anchor) {
  var container = jQuery(anchor);

  var input = container.find('>input[type=checkbox]');
  var offset = container.offset().top;

  jQuery(input).prop('checked', true);
  jQuery('html, body').animate({ scrollTop: offset }, 500);
}

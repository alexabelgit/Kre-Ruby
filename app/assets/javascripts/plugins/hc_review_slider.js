jQuery.fn.hc_review_slider_scroll = function() {
  scroll_button = jQuery('[data-hc_review_slider_scroll_button]')
  list          = jQuery('[data-hc-review-slider-list]')
  offset        = list.children().first().outerWidth( true )
  duration      = 250

  scroll_button.click( function() {
    if (list.is(':animated')) {
      return false;
    }

    current_position = list.scrollLeft();

    if (jQuery(this).is('[data-hc_review_slider_scroll_left]')) {
      list.animate({ scrollLeft: current_position - offset }, duration);
    }

    if (jQuery(this).is('[data-hc_review_slider_scroll_right]')) {
      list.animate({ scrollLeft: current_position + offset }, duration);
    }
  })
};

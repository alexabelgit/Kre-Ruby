jQuery(document).on('turbolinks:load', function() {
  $("#settings_reviews_auto_publish").click( (event) => {
    if(event.target.checked) {
      $(".hc-form__minimum-ratings").removeClass('hide');
    } else {
      $(".hc-form__minimum-ratings").addClass('hide');
    }
  });
});

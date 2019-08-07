jQuery.fn.hc_dropdown = function() {
  this.find('[data-hc-dropdown]').each(function (){
    var dropdown = jQuery(this);
    var trigger  = dropdown.find('[data-hc-dropdown-trigger]');
    // var content  = dropdown.find('[data-hc-dropdown-content]');

    trigger.click(function(e) {
      // var was_active = content.hasClass('hc-dropdown__content--active');
      var was_active = dropdown.hasClass('hc-dropdown--active');
      jQuery('.hc-dropdown--active').removeClass('hc-dropdown--active');
      if (!was_active)
        dropdown.addClass('hc-dropdown--active');
      e.preventDefault();
      e.stopPropagation();
    });

    jQuery(document).click(function(e) {
      var target = jQuery(e.target);
      if(!target.is(dropdown) && target.parents('.hc-dropdown--active').length <= 0){
        dropdown.removeClass('hc-dropdown--active');
      }
    });
  });
  return this;
};

jQuery.fn.sidify = function() {
  var item = jQuery(this);
  item.find('[data-role="sidebar-trigger"]').click(function (){
    var modal_list_container = item.find('.hc-sidebar__wrapper');
    if (modal_list_container.hasClass('hc-hide'))
      modal_list_container.addClass('hc-show').removeClass('hc-hide');
    else
      modal_list_container.addClass('hc-hide').removeClass('hc-show');
  });
  return this;
};

jQuery.fn.hc_scroll_to = function() {
  var elem = this
  this.find('[data-hc-scroll-to]').each(function (){
    var link = jQuery(this);
    // This code checks if a data-href value is already present in the link. This will not override the existing href of the link. (Userful for summary floating ratings chart)
    var data_href = link.attr('data-href');
    if (data_href === "" || data_href === undefined){
      link.attr('data-href', link.attr('href'));
      link.attr('href', 'javascript:void(0);')
    }
    link.click(function(event) {
      event.preventDefault();
      var href = link.attr('data-href');
      var target = link.attr("data-hc-scroll-target")
      if (href !== "" || href !== undefined){
        jQuery('#hc-product-tabs').find('[data-tab="true"][data-role="'+ href.split('-')[1] + '"]').trigger('click'); // TODO scroll to must be more general not depending on presence of tabs
      }
      if (target !== "" || href !== undefined){
        jQuery('html,body').animate({ scrollTop: jQuery(target).first().offset().top - 15 }, 500);
      }
    });
  })
  return this;
};

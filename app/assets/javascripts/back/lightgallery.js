jQuery(document).on('turbolinks:load', function() {
  jQuery('[data-lightgallery="true"]').each(function (){
    jQuery(this).hc_lightbox().detoggle_lightbox();
  });
});

jQuery.fn.detoggle_lightbox = function() {
  var that = jQuery(this);
  that.find('[data-role="medium-status-toggler"]').bindFirst('click', function (e){
    var that = jQuery(this);
    jQuery.ajax({
      url:     that.attr('href'),
      type:    that.attr('data-method'),
      success: function(result) {
      }
    });
    e.stopPropagation();
    e.preventDefault();
  });
  return this;
};

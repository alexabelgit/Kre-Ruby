jQuery.fn.hc_lightbox = function() {
  var list = jQuery(this).is('[data-lightgallery="true"]') ? jQuery(this) : jQuery(this).find('[data-lightgallery="true"]');
  list.lightGallery({preload: 0, download: false});
  return this;
};

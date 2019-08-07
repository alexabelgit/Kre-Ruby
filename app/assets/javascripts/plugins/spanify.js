jQuery.fn.spanify = function() {
  this.replaceWith(function(){
    var that = jQuery(this);
    return jQuery('<span>' + that.html() + '</span>').attr('class', that.attr('class')).addClass('disabled');
  });
};

// TODO @nkadze add readme on what this does.. have no clue

(function(jQuery) {
  jQuery.fn.inner_html_change = function(cb, e) {
    e = e || { subtree:true, childList:true, characterData:true };
    jQuery(this).each(function() {
      function callback(changes) { cb.call(node, changes, this); }
      var node = this;
      (new MutationObserver(callback)).observe(node, e);
    });
  };
})(jQuery);

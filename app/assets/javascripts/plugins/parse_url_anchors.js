jQuery.fn.parse_url_anchors = function() {
  if (window.location.hash.length) {
    var anchor = window.location.hash;

    slide_to_anchor(anchor);
  }
}

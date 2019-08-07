// run javascript before ajax execution on remote links with before attribute
jQuery(document).on('turbolinks:load', function() {
  var that = jQuery(this);
  that.on('ajax:beforeSend', 'a[data-remote=true][before]', function(event, xhr, status, error) {
    var link = jQuery(this);
    eval(link.attr('before'));
  });
});

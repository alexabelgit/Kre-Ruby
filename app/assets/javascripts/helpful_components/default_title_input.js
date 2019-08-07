jQuery(document).on('turbolinks:load', function() {
  function enableDefaultTitle(element) {
    var parent = element.closest('.default-title__control');
    checked_checkbox = $('#' + element.attr('id') + ':checked');
    if (checked_checkbox.length >= 1) {
	    parent.find('.default-title__current').hide();
	    parent.find('.default-title__new').show();
    } else {
    	parent.find('.default-title__current').show();
	    parent.find('.default-title__new').hide();
    }
  }

  $('.default-title__control').on('change', '[data-target="default_title_input"]', function() {
    enableDefaultTitle($(this));
  });
  $('.default-title__control [data-target="default_title_input"]').each(function() {
  	enableDefaultTitle($(this));
  });
});

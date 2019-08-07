jQuery.fn.hc_reset_search = function() {
	this.find('.js-reset-search').each(function (){
		var clear_button = $(this).find('.js-reset-search-button');
		var input = $(this).find('input');
		hc_toggle_reset(input, clear_button);
		input.on('input', function(){
			hc_toggle_reset($(this), clear_button);
		});
	});
}

hc_toggle_reset = function(input, clear_button) {
	if(input.val() != "") {
		clear_button.css('display', 'inline');
	} else {
		clear_button.hide();
	}
}
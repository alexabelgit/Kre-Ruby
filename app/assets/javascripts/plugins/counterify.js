jQuery.fn.counterify = function() {
  var item = jQuery(this);
  if (!item.is('textarea'))
    item = item.find('textarea[data-counterify!="initialized"]');
  if (item.length > 0 && item.attr('data-counterify') != 'initialized') {
    item.keyup(function () {
      var textarea = jQuery(this);
      var form = textarea.parents('form').first();
      var character_count_container = form.find('[data-role="character-count"]');

      var text_length = textarea.val().replace(/(\r\n|\n|\r)/g, '--').length;

      if (text_length > 3000)
        character_count_container.removeClass('warning').addClass('error').html('Character limit exceeded');
      else if (text_length > 2980) {
        character_count_container.removeClass('error').addClass('warning').html((3000 - text_length) + ' characters remaining');
      }
      else if (text_length > 2950)
        character_count_container.removeClass('error').removeClass('warning').html((3000 - text_length) + ' characters remaining');
      else
        character_count_container.removeClass('error').removeClass('warning').html('');

      if (text_length <= 3000){
        form.find('[type="submit"]').removeAttr('disabled');
      } else {
        form.find('[type="submit"]').attr('disabled', 'disabled');
      }
    });
    item.keydown(function (){
      var textarea = jQuery(this);
      var text_length = textarea.val().replace(/(\r\n|\n|\r)/g, '--').length;
      if (text_length >= 3000){
        var form = textarea.parents('form').first();
        form.find('[type="submit"]').attr('disabled', 'disabled');
      }
    });
    item.attr('data-counterify', 'initialized');
  }
  return this;
};

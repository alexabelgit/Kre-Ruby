jQuery.fn.promptable = function() {
  var item = jQuery(this);
  item.find('[data-prompt="true"]').click(function (e) {
    var that = jQuery(this);
    console.log(that);
    console.log(that.attr('data-prompt-message'));
    console.log(that.attr('data-prompt-confirm'));
    var answer = prompt(that.attr('data-prompt-message'));
    if (!answer || answer != that.attr('data-prompt-confirm')){
      alert('The input is not correct');
      e.preventDefault();
    }
  });
}

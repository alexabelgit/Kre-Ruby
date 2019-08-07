jQuery.fn.copy_to_clipboard = function() {
  this.find('.js-copy-to-clipboard').each(function(){
    var trigger = jQuery(this);

    trigger.click(function(e) {
      e.preventDefault();
      if (trigger.is("select")) {
        var option = trigger.find("option:selected");
        var copyThis = option.data('copy-to-clipboard-content');
      } else if (trigger.is("span")) {
        var copyThis = trigger.text();
      } else {
        if (trigger.data('copy-to-clipboard-content') == 'href') {
          var copyThis = trigger.attr('href')
        } else {
          var copyThis = trigger.data('copy-to-clipboard-content')
        }
      }

      var textArea = document.createElement("textArea");

      textArea.value     = copyThis;
      textArea.className = 'hide-unless-screen-reader'

      trigger.after(textArea);
      textArea.focus();
      textArea.select();

      var fallback = function(){ prompt('Copy following content to clipboard by pressing Ctrl+C (Cmd+C on Mac):', copyThis) }

      try {
        var successful = document.execCommand('copy');
        if (successful == true) {
          if (trigger.is("select") || trigger.is("span")) {
            var option = trigger.find("option:selected");
            if (option.data('copy-to-clipboard-success')) {
              msg = option.data('copy-to-clipboard-success')
            } else if (trigger.is("span")) {
              msg = "<b>" + copyThis  + "</b> copied";
            } else {
              msg = "Copied"
            }

            var tooltip = trigger.siblings('.hc-tooltip').find('.hc-tooltip__content')
            tooltip.css({'opacity': '1', 'visibility': 'unset'});
            setTimeout(function() {
              tooltip.css({'opacity': '0', 'visibility': 'hidden'});
            }, 1000);

            tooltip.find('span').html(msg);
          // } else if (trigger.is("span")) {

          } else {
            if (trigger.data('copy-to-clipboard-success')) {
              msg = trigger.data('copy-to-clipboard-success')
            } else {
              msg = "Copied"
            }
            trigger.html(msg)
          }
        } else {
          fallback();
        }
      } catch(err) {
        fallback();
      }

      textArea.remove();

    });
  });
  return this;
}

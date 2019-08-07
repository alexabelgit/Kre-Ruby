jQuery(document).on('turbolinks:load', function() {

  if (jQuery('#settings-form__custom_stylesheet').length) {
    var editor = ace.edit("settings-form__custom_stylesheet");
    var textarea = jQuery('#settings-form__custom_stylesheet-textarea');

    editor.setOptions({
      fontSize: "9.5pt",
      mode: "ace/mode/css",
      theme: "ace/theme/clouds",
      showPrintMargin: false,
      maxLines: 30,
      useSoftTabs: true,
      tabSize: 2
    });

    editor.session.$worker.call('setDisabledRules', ["important"]);

    editor.getSession().setValue(textarea.val());
    editor.getSession().on('change', function(){
      textarea.val(editor.getSession().getValue());
    });
  }

})

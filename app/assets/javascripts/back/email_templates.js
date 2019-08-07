jQuery(document).on('turbolinks:load', function() {

  jQuery(document).previewable();
  initTinymce();

  jQuery('.template--email input, .template--email textarea, .template--email select').on ('keyup change', function() {
    template = jQuery(this).closest('.template--email');
    saveTemplate(template);
  })

  jQuery('.template__preview-button button').on ('click', function() {
    template = jQuery(this).closest('.template--email');
    saveTemplate(template);
  })

  jQuery('.hc-collapsible-item').on ('click', function() {
    container = jQuery(this).find('.template__source-and-preview');
    setPreviewContainerHeight(container);
  })

  jQuery('.template__send-test-email .hc-primary-button').on ('click', function() {
    disableSendButton(this)
  })

  jQuery(window).resize(function () {
    setPreviewContainerHeight(jQuery('.template__source-and-preview'));
  })

});

function setPreviewContainerHeight(container) {
  sourceHeight = container.find('.template__source').outerHeight();
  jQuery(container).height(sourceHeight);
}

function saveTemplate(template) {
  jQuery(template).submit();
  animateTemplateIcons(template);
}

function animateTemplateIcons(template) {
  if ('id1' in window)
    clearTimeout(id1);
  if ('id2' in window)
    clearTimeout(id2);
  if ('id3' in window)
    clearTimeout(id3);
  if ('id4' in window)
    clearTimeout(id4);

  hideSaveIcon(template);
  hideChevronIcon(template);
  showSpinIcon(template);

  id1 = setTimeout(function() {
    hideSpinIcon(template);
  }, 500);
  id2 = setTimeout(function() {
    showSaveIcon(template);
  }, 500);
  id3 = setTimeout(function() {
    hideSaveIcon(template);
  }, 2000);
  id4 = setTimeout(function() {
    showChevronIcon(template);
  }, 2000);
}

function showChevronIcon() {
  jQuery(template).find('.template__preview-button .hc-icon--chevron-right').show();
}

function showSpinIcon() {
  jQuery(template).find('.template__preview-button .hc-icon--hc-spinner').show();
}

function showSaveIcon() {
  jQuery(template).find('.template__preview-button .hc-icon--save').show();
}

function hideChevronIcon() {
  jQuery(template).find('.template__preview-button .hc-icon--chevron-right').hide();
}

function hideSpinIcon() {
  jQuery(template).find('.template__preview-button .hc-icon--hc-spinner').hide();
}

function hideSaveIcon() {
  jQuery(template).find('.template__preview-button .hc-icon--save').hide();
}

function initTinymce() {
  var selectors = ['textarea#settings_review_request_mail_body', 'textarea#settings_repeat_review_request_mail_body', 'textarea#settings_positive_review_followup_mail_body', 'textarea#settings_critical_review_followup_mail_body', 'textarea#settings_comment_mail_body', 'textarea#promotion_template'];

  selectors.forEach(initTextarea);
}

function initTextarea(selector) {
  tinymce.init({
    selector: selector,
    statusbar: false,
    menubar: false,
    toolbar: 'bold italic alignleft aligncenter alignright',
    // plugins: "autoresize",
    // autoresize_bottom_margin: 30,
    // autoresize_on_init: false,
    height: 300,
    setup: function(editor) {
      editor.on('keyup change', function() {
        var content = tinymce.activeEditor.getContent({format: 'html'});
        jQuery(selector).val(content).trigger("change");
      });
    }
  });
}

function disableSendButton(button) {
  button = jQuery(button);
  button.text("Sent!");
  button.removeClass("hc-primary-button");
  button.addClass("hc-success-button disabled");
  button.attr("disabled", true);
  setTimeout(function() {
    enableSendButton(button)
  }, 3000);
}

function enableSendButton(button) {
  button.text("Send Test");
  button.removeClass("hc-success-button disabled");
  button.addClass("hc-primary-button");
  button.attr("disabled", false);
}

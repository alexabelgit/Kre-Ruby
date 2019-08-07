jQuery.fn.remotify = function() {
  if (typeof Turbolinks === 'undefined') {
    this.find('a[target!="_blank"][data-remote="true"][data-remotify!="true"]').each(function () {
      var anchor = jQuery(this);
      anchor.attr('data-remotify', 'true');
      anchor.on("click", function(e) {
        switch (anchor.data('method')) {
          case 'post':
            jQuery.ajax({
              url: anchor.attr('href'),
              type: 'POST',
              dataType: 'text',
              success: function(js) {
                eval(js);
              }
            });
            break;
          default :
            jQuery.ajax({
              url: anchor.attr('href'),
              type: 'GET',
              dataType: 'text',
              success: function(js) {
                eval(js);
              }
            });
            break;
        }
        return false;
      });
    });
    this.find('form[data-remote="true"][data-remotify!="true"]').each(function() {
      var form = jQuery(this);
      form.attr('data-remotify', 'true');
      if (form.attr('enctype') == 'multipart/form-data'){
        form.submit(function(e) {
          var data = new FormData();
          form.find('input[type="file"]').each(function() {
            var file_input = jQuery(this);
            var file_input_name = file_input.attr('name');
            jQuery.each(file_input[0].files, function(i, file) {
                data.append(file_input_name, file);
            });
          });
          form.find('input[type!="file"][type!="radio"],input[type="radio"]:checked,textarea').each(function() {
            var input = jQuery(this);
            data.append(input.attr('name'), input.val());
          });
          jQuery.ajax({
            url: form.attr('action'),
            type: form.attr('method'),
            data: data,
            cache: false,
            contentType: false,
            processData: false,
            beforeSend: function() {
              disableSubmitButton(form)
            },
            success: function(js) {
            },
            error: function() {
              enableSubmitButton(form)
            }
          });
          return false;
        });
      } else {
        form.submit(function(e) {
          jQuery.ajax({
            url: form.attr('action'),
            type: form.attr('method'),
            data: form.serialize(),
            dataType: 'text',
            beforeSend: function() {
              disableSubmitButton(form)
            },
            success: function(js) {
              eval(js);
            },
            error: function() {
              enableSubmitButton(form)
            }
          });
          return false;
        });
      }
    });
  }
  return this;
};

function disableSubmitButton(form) {
  button = form.find('[type="submit"]')
  button.attr('disabled', 'true');
  button.html(button.attr('data-disable-with'));
}

function enableSubmitButton(form) {
  button = form.find('[type="submit"]')
  button.removeAttr('disabled');
  button.find($('svg').remove());
}

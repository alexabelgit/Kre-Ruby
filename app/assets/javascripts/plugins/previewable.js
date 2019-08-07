jQuery.fn.previewable = function() {
  var item = jQuery(this);

  var escapeHtml = function(unsafe) {
    return unsafe.replace(/(\r\n|\n|\r)/g, "");
  };

  var process_preview = function (role){
    var output      = $('[data-previewable="input"][data-role="' + role + '"]').val();
    var sample_data = JSON.parse($('script[data-previewable="sample_data"]').html());

    for(var k in sample_data) {
      output = output.split('[' + k + ']').join(sample_data[k]);
    }

    if (role == 'facebook' || role == 'twitter') {
      var output = output.replace(/\n\s*\n\s*\n/g, '\n\n');
      // TODO substitute regex with smt similar to this: https://stackoverflow.com/a/10805292/1950438
    }

    if (role == 'twitter' && output.length > 143) {
      var output = output.substring(0, 143) + '&hellip;'
    }

    var output = escapeHtml(output);

    $('[data-previewable="output"][data-role="' + role + '"]').html(output);
  };

  var processed_data_roles = [];
  $('[data-previewable][data-role]').each(function (){
    var data_roles = $(this).attr('data-role').split(',');
    for(var i in data_roles) {
      if (processed_data_roles.indexOf(data_roles[i]) === -1) {
        process_preview(data_roles[i]);
        processed_data_roles.push(data_roles[i]);
      }
    }
  });

  item.find('[data-previewable="button"]').click(function (e) {
    var that = jQuery(this);
    updatePreview(e, that);
  });

  item.find('.template__source-and-preview .hc-form__input, .template__source-and-preview textarea, .template__source-and-preview .tox-tinymce').on ('keyup change', function (e) {
    var that = jQuery(this);
    updatePreview(e, that);
  });

  function updatePreview(e, that) {
    var data_roles = that.attr('data-role').split(',');
    for(var i in data_roles) {
      process_preview(data_roles[i]);
    }
  }

  return this;
};

jQuery.fn.hc_upload_button = function() {
  this.find('[data-hc-upload-button]').each(function() {
    var upload_button    = jQuery(this)
    var file_input       = upload_button.find('[data-hc-upload-button-input]');
    var filename_wrapper = upload_button.find('[data-hc-upload-button-filename]');

    file_input.change(function(e) {
      var filename = "No file chosen"
      var files    = file_input.prop('files')

      if (files && files.length > 1)
        var filename = files.length + ' files'
      else if (files)
        var filename = files[0].name

      filename_wrapper.html(filename)
    });
  });
  return this;
};

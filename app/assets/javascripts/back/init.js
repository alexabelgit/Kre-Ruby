if (!window.BackApp) { window.BackApp = {}; }


BackApp.executeBeforeAttributeOnLinks = (self) => {
  const that = jQuery(self);

  that.on('ajax:beforeSend', 'a[data-remote=true][before]', function(event, xhr, status, error) {
    const link = jQuery(this);
    const beforeBody = link.attr('before');
    eval(beforeBody);
  });
}


BackApp.init = (self) =>
  BackApp.executeBeforeAttributeOnLinks(self);

$(document).on('turbolinks:load', function() {
  BackApp.init(this);
});


jQuery(document).on('turbolinks:load', function() {

  jQuery(this).copy_to_clipboard();
  jQuery(this).parse_url_anchors();

  function toggleMockupImage(element) {
    parent = element.closest('.settings__about');
    image = parent.find('.settings__mockup img')

    if (element.is(':radio')) {
      value = element.attr('data-trigger');
      selectedImage = parent.find('[data-image="' + value + '"]')
      if (element.is(':checked')){
        image.hide();
        selectedImage.show();
      }
    }

    if (element.is(':checkbox')) {
      image.hide();
      if (element.is(':checked')) {
        parent.find('[data-image="1"]').show()
      } else {
        parent.find('[data-image="0"]').show()
      }
    }
  }

  function setMockupImages(parent) {
    parent.find('[data-target="mockup_image"]').each(function(){
      toggleMockupImage($(this))
    })
  }

  // Show the mockup image for the option which is checked
  setMockupImages($('.settings__about'))

  // Change the mockup images based on user selection
  $('.settings__about').on('click', '[data-target="mockup_image"]', function(){
    toggleMockupImage($(this));
  });
});

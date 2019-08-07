jQuery.fn.modal_form = function() {
  var item = jQuery(this);
  item.find('[data-role$="-form-toggle"][data-modal-form-toggle-initialized!="true"]')
    .attr('data-modal-form-toggle-initialized', 'true').click(function (){
      var toggler = jQuery(this);
      var role    = toggler.attr('data-role').replace('-toggle', '');
      var form    = item.find('[data-role$="' + role + '"]');
      var model   = '';
      if(role.includes('review')){
        model = 'reviews';
        var all_togglers = item.find('[data-role$="review-form-toggle"]')
      }
      else if(role.includes('question')){
        model = 'questions';
        var all_togglers = item.find('[data-role$="question-form-toggle"]')
      }

      all_togglers.each(function(){
        jQuery(this).css('display','inline-block');
      })
      if (toggler.data('action') == 'show') {
        form.addClass('hc-display__block').removeClass('hc-display__none');
        jQuery('.system-message').addClass('hc-display__none');
        item.find('[data-tab="true"][data-role="'+model+'"]').trigger('click');
        if(toggler.data('toggle-with-form')) {
          toggler.css('display','none');
        }
      }
      else if (toggler.data('action') == 'hide') {
        form.addClass('hc-display__none').removeClass('hc-display__block');
        if(toggler.data('toggle-with-form')) {
          toggler.css('display','inline-block');
        }
      }
    });

  return this;
};

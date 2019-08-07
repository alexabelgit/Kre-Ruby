//= require cable
//= require_self

App.cable.subscriptions.create('OnboardingChannel', {
  received: function(data) {
    jQuery('[data-role="' + data.object + '"]').replaceWith(data.view);
  }
});

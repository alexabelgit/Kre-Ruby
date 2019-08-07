//= require cable
//= require_self

App.cable.subscriptions.create('ShopifyChannel', {
  received: function(data) {
    if (data.js && (!data.js.indicator || jQuery(data.js.indicator).length > 0))
      eval(data.js.code);
  }
});

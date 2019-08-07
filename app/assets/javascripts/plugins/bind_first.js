// TODO @nkadze add readme on what this does.. have no clue

jQuery.fn.bindFirst = function(name, fn) {
  this.bind(name, fn);
  if (this.data('events')) {
    var handlers = this.data('events')[name.split('.')[0]];
    var handler  = handlers.pop();
    handlers.splice(0, 0, handler);
  } else {
      this.each(function() {
        var handlers = jQuery._data(this, 'events')[name.split('.')[0]];
        var handler  = handlers.pop();
        handlers.splice(0, 0, handler);
    });
  }
};

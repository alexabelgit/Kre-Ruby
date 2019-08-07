jQuery(document).on('turbolinks:load', function() {
    new Choices('.hc-select-with-search', {
        maxItemCount: 1
    });
});
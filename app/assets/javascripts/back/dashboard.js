jQuery(document).on('turbolinks:load', function() {
  jQuery('select[data-role="filter-rating"]').change(function (){
    jQuery.get(HC_JS.routes.product_stats_back_dashboard_index_path({product_id: jQuery(this).val(), format: 'js'}), function(){});
  });
});

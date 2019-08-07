class ShopifyReviewsParser

  SHOPIFY_IMPORT_REVIEW_FIELDS = OpenStruct.new(product_id_field:     'product_handle',
                                                rating_field:         'rating',
                                                title_filed:          'title',
                                                feedback_field:       'body',
                                                customer_name_field:  'author',
                                                customer_email_field: 'email',
                                                comment_field:        'reply',
                                                review_date_field:    'created_at',
                                                status_field:         'state').freeze

  SHOPIFY_IMPORT_REVIEW_REQUIRED_FIELDS = OpenStruct.new(product_id_field:     'product_handle',
                                                         rating_field:         'rating',
                                                         feedback_field:       'body',
                                                         customer_email_field: 'email').freeze

  def self.parse(csv, store_id)
    res = []
    csv.each do |shopify_data|
      element = {}
      Importers::ReviewsCsvImporter::IMPORT_REVIEW_FIELDS.marshal_dump.each do |key, field_name|
        shopify_value = shopify_data[SHOPIFY_IMPORT_REVIEW_FIELDS[key]]
        case key
          when :product_id_field
            shopify_value = Product.where(store_id: store_id).where("url like '%#{shopify_value}'").pluck(:id_from_provider).first
          when :feedback_field
            shopify_value = Rumoji.decode shopify_value
          when :review_date_field	
            shopify_value = DateTime.strptime(shopify_value, "%Y-%m-%d %H:%M:%S %z").to_s
        end
        element[field_name] = shopify_value
      end
      extra_fields = shopify_data.keys - SHOPIFY_IMPORT_REVIEW_FIELDS.marshal_dump.values
      extra_fields.each do |field|
        element['shopify_' + field] = shopify_data[field]
      end
      res << element
    end
    res
  end    

end
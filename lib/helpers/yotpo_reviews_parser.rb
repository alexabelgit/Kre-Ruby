class YotpoReviewsParser

  YOTPO_IMPORT_REVIEW_FIELDS = OpenStruct.new(product_id_field:     'product_id',
                                              rating_field:         'review_score',
                                              title_filed:          'review_title',
                                              feedback_field:       'review_content',
                                              customer_name_field:  'display_name',
                                              customer_email_field: 'email',
                                              comment_field:        'comment_content',
                                              review_date_field:    'date',
                                              verified_field:       'user_type',
                                              status_field:         'published').freeze
  
  YOTPO_IMPORT_REVIEW_REQUIRED_FIELDS = OpenStruct.new(product_id_field:     'product_id',
                                                       rating_field:         'review_score',
                                                       feedback_field:       'review_content',
                                                       customer_email_field: 'email').freeze

  def self.parse(csv)
    res = []
    csv.each do |yotpo_data|
      element = {}
      Importers::ReviewsCsvImporter::IMPORT_REVIEW_FIELDS.marshal_dump.each do |key, field_name|
        yotpo_value = yotpo_data[YOTPO_IMPORT_REVIEW_FIELDS[key]]
        case key
          when :verified_field
            yotpo_value = yotpo_value == 'verified_buyer' ? 'yes' : 'no'
          when :status_field
            yotpo_value = yotpo_value == 'TRUE' ? 'published' : 'pending'
          when :feedback_field
            yotpo_value = Rumoji.decode yotpo_value
        end
        element[field_name] = yotpo_value
      end
      extra_fields = yotpo_data.keys - YOTPO_IMPORT_REVIEW_FIELDS.marshal_dump.values
      extra_fields.each do |field|
        element['yotpo_' + field] = yotpo_data[field]
      end
      res << element
    end
    res
  end

  def self.parse_to_yotpo(csv)
    res = []
    csv.each do |data|
      element = {}
      YOTPO_IMPORT_REVIEW_FIELDS.marshal_dump.each do |key, field_name|
        value = data[Importers::ReviewsCsvImporter::IMPORT_REVIEW_FIELDS[key]]
        case key
          when :verified_field
            value = value == 'yes' ? 'verified_buyer' : 'anonymous'
          when :status_field
            value = value == 'published' ? 'TRUE' : 'FALSE'
          when :feedback_field
            value = Rumoji.encode(value)
        end
        element[field_name] = value
      end
      extra_fields = data.keys - Importers::ReviewsCsvImporter::IMPORT_REVIEW_FIELDS.marshal_dump.values
      extra_fields.each do |field|
        element[field[6..-1]] = data[field]
      end
      res << element
    end
    res
  end

end

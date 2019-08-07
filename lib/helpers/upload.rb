class Upload
  IMPORT_REVIEW_FIELDS =
    {
      shopify: {
        product_id_field:     'product_handle',
        rating_field:         'rating',
        title_filed:          'title',
        feedback_field:       'body',
        customer_name_field:  'author',
        customer_email_field: 'email',
        comment_field:        'reply',
        review_date_field:    'created_at',
        status_field:         'state'
      },
      yotpo: {
        product_id_field:     'product_id',
        rating_field:         'review_score',
        title_filed:          'review_title',
        feedback_field:       'review_content',
        customer_name_field:  'display_name',
        customer_email_field: 'email',
        comment_field:        'comment_content',
        review_date_field:    'date',
        verified_field:       'user_type',
        status_field:         'published'
      },
      default: {
        product_id_field:     'product_id',
        rating_field:         'rating',
        title_filed:          'title',
        feedback_field:       'feedback',
        customer_name_field:  'customer_name',
        customer_email_field: 'customer_email',
        comment_field:        'comment',
        status_field:         'status',
        review_date_field:    'review_date',
        verified_field:       'verified',
        type_field:           'review_type',
        media_1:              'media_1',
        media_2:              'media_2',
        media_3:              'media_3',
        media_4:              'media_4',
        media_5:              'media_5'
      }
    }

  IMPORT_REVIEW_REQUIRED_FIELDS =
    {
      shopify: {
        product_id_field:     'product_handle',
        rating_field:         'rating',
        feedback_field:       'body',
        customer_email_field: 'email',
      },
      yotpo: {
        product_id_field:     'product_id',
        rating_field:         'review_score',
        feedback_field:       'review_content',
        customer_email_field: 'email'
      },
      default: {
        product_id_field:     'product_id',
        rating_field:         'rating',
        feedback_field:       'feedback',
        customer_email_field: 'customer_email'
        }
      }

  IMPORT_QUESTION_FIELDS =
    {
      product_id_field:     'product_id',
      question_field:       'question',
      customer_name_field:  'customer_name',
      customer_email_field: 'customer_email',
      answer_field:         'answer',
      status_field:         'status',
      question_date_field:  'question_date',
      verified_field:       'verified'
    }

  IMPORT_QUESTION_REQUIRED_FIELDS =
    {
      product_id_field:     'product_id',
      question_field:       'question',
      customer_email_field: 'customer_email'
    }

  IMPORT_REVIEW_REQUEST_FIELDS =
    {
      product_ids_field:    'product_ids',
      customer_name_field:  'customer_name',
      customer_email_field: 'customer_email',
      scheduled_for_field:  'scheduled_for',
      type_field:           'review_type'
    }

  IMPORT_REVIEW_REQUEST_REQUIRED_FIELDS =
    {
      product_ids_field:    'product_ids',
      customer_email_field: 'customer_email'
    }

  IMPORT_PRODUCT_FIELDS =
    {
      product_id_field:        'id',
      product_name_field:      'name',
      product_url_field:       'url',
      product_image_url_field: 'image_url',
    }

  IMPORT_PRODUCT_REQUIRED_FIELDS =
    {
      product_id_field:   'id',
      product_name_field: 'name',
      product_url_field:  'url'
    }

  CLOUDINARY_VIDEO_FORMATS = ['3g2', '3gp', '3gpp', 'asf', 'avi', 'dat', 'divx', 'dv', 'f4v', 'flv', 'm2ts', 'm4v', 'mkv',
                              'mod', 'mov', 'mp4', 'mpe', 'mpeg', 'mpeg4', 'mpg', 'mts', 'nsv', 'ogm', 'ogv', 'qt', 'tod',
                              'ts',  'vob', 'wmv']
  CLOUDINARY_IMAGE_FORMATS = ['jpeg', 'jpg', 'png', 'gif', 'bmp']

  REVIEW_TYPES =
    {
      type_product:     'product',
      type_business:    'business'
    }

  def self.check_columns(column_names, csv_type, provider)
    case csv_type
    when 'review'
      return (IMPORT_REVIEW_REQUIRED_FIELDS[provider.to_sym].values - column_names).empty?
    when 'question'
      return (IMPORT_QUESTION_REQUIRED_FIELDS.values - column_names).empty?
    when 'review_request'
      return (IMPORT_REVIEW_REQUEST_REQUIRED_FIELDS.values - column_names).empty?
    when 'product'
      return (IMPORT_PRODUCT_REQUIRED_FIELDS.values - column_names).empty?
    end
  end
end

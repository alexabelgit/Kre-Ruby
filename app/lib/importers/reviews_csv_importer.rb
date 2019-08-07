module Importers
  class ReviewsCsvImporter
    attr_reader :store

    IMPORT_REVIEW_FIELDS = OpenStruct.new(product_id_field:     'product_id',
                                          rating_field:         'rating',
                                          title_filed:          'title',
                                          feedback_field:       'feedback',
                                          customer_name_field:  'customer_name',
                                          customer_email_field: 'customer_email',
                                          comment_field:        'comment',
                                          status_field:         'status',
                                          review_date_field:    'review_date',
                                          verified_field:       'verified',
                                          media_1:              'media_1',
                                          media_2:              'media_2',
                                          media_3:              'media_3',
                                          media_4:              'media_4',
                                          media_5:              'media_5')
  
    IMPORT_REVIEW_REQUIRED_FIELDS = OpenStruct.new( product_id_field:     'product_id',
                                                    rating_field:         'rating',
                                                    feedback_field:       'feedback',
                                                    customer_email_field: 'customer_email')

    delegate  :product_id_field, :rating_field, :title_filed, :feedback_field, :customer_name_field,
              :customer_email_field, :comment_field, :status_field, :review_date_field, :verified_field,
              to: :IMPORT_REVIEW_FIELDS

    def initialize(store)
      @store = store
    end

    def self.valid?(column_names, provider = nil)
      provider ||= :default
      case provider.to_sym
        when :default
          (IMPORT_REVIEW_REQUIRED_FIELDS - column_names).empty?
        when :yotpo
          (YotpoReviewsParser::YOTPO_IMPORT_REVIEW_REQUIRED_FIELDS - column_names).empty?
        when :shopify
          (ShopifyReviewsParser::SHOPIFY_IMPORT_REVIEW_REQUIRED_FIELDS - column_names).empty?
      end
    end

    def import(csv, provider)
      provider ||= :default
      case provider.to_sym
        when :yotpo
          csv = YotpoReviewsParser.parse csv
        when :shopify
          csv = ShopifyReviewsParser.parse csv, store.id
      end
      
      Searchkick.callbacks(false) do
        csv.reverse_each.map do |review_data|
          import_row review_data
        end.compact
      end
    end

    def import_row review_data
      product        = store.products.find_by id_from_provider: review_data[product_id_field]
      rating         = review_data[rating_field]
      title          = review_data[title_filed]
      feedback       = review_data[feedback_field]
      customer_name  = review_data[customer_name_field]
      customer_email = review_data[customer_email_field]
      comment        = review_data[comment_field]
      status         = review_data[status_field]
      status         = ImportedReview.statuses[:pending] unless ImportedReview.statuses.keys.include?(status)
      review_date    = review_data[review_date_field]
      review_date    = '' unless review_date.present?
  
      if customer_email.present?
        customer = store.customers.find_or_create_by(email: customer_email) do |customer|
          customer.name                  = customer_name.present? ? customer_name : customer_email
          customer.id_from_provider      = customer_email
          customer.skip_reindex_children = true
        end
        customer.update name: customer_name, skip_reindex_children: true if customer_name.present?
      end

      begin
        review_date = DateTime.parse(review_date)
      rescue ArgumentError
        review_date = nil
      end

      is_business_review = review_data[product_id_field].nil?

      unless (product.present? || is_business_review) && rating.present? && (rating.is_a?(Numeric) || rating.is_number?) && feedback.present? && customer.present? && customer.persisted? && review_date.present? && review_date <= DateTime.current
        return review_data
      end

      imported_review = ImportedReview.new( product:     product,
                                            rating:      rating,
                                            title:       title,
                                            feedback:    feedback,
                                            customer:    customer,
                                            comment:     comment,
                                            status:      status,
                                            review_date: review_date,
                                            verified:    review_data[verified_field].present? && review_data[verified_field].downcase == 'yes')

      if imported_review.save
        (1..5).each do |i|
          media_url = review_data["media_#{i}"]
          if media_url.present? && media_url.valid_as_uri?
            public_id = "unassigned-media/#{SecureRandom.uuid}"
            if Cloudinary::Uploader.upload(media_url, public_id: public_id)
              Medium.create(mediable: imported_review, media_type: 'image', cloudinary_public_id: public_id)
            end
          end
        end
      else
        return review_data
      end
      
      nil
    end

  end
end
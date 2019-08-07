module Export
  class ReviewsCsvExport
    attr_reader :reviews, :timezone
  
    CSV_HEADERS = %w[product_id rating feedback customer_name customer_email comment status review_date verified media1 media2 media3 media4 media5 id product_name].freeze
  
    def initialize(reviews: Review.all, timezone: Time.zone)
      @reviews = reviews
      @timezone = timezone
    end
  
    def generate
      data = prepare_csv_data
  
      CSV.generate(headers: true) do |csv|
        csv << CSV_HEADERS
        data.each { |row| csv << row }
      end
    end
  
    private
  
    def prepare_csv_data
      query = reviews.left_outer_joins(:products)
                    .joins(:customer)
                    .joins("LEFT OUTER JOIN comments ON comments.commentable_id = reviews.id AND comments.commentable_type = 'Review'")
                    .order('reviews.id ASC')
                    .includes(:media)
      data = query.pluck(pluck_query)

      model = reviews.model
      media = reviews.map { |r| [r.id, r.media.map(&:public_url)] }.to_h

      keys = CSV_HEADERS.map(&:to_sym)
      data.map do |row|
        hash = keys.zip(row).to_h

        media_urls = media[hash[:id]]
        if media_urls.present?
          hash.merge! media_urls.map.with_index { |url, index| ["media#{index+1}".to_sym, url] }.to_h
        end

        hash[:id] = model.encode_id hash[:id]
        hash[:review_date] = hash[:review_date]&.in_time_zone(timezone)
        hash.values
      end
    end
  
    def pluck_query
      <<SQL
        products.id_from_provider, reviews.rating, reviews.feedback,
        customers.name, customers.email,
        COALESCE(comments.body, '') AS comment_body, reviews.status, reviews.review_date,
        CASE reviews.verification
          WHEN 1 THEN 'Yes'
          WHEN 2 THEN 'Yes'
          WHEN 0 THEN 'No'
          ELSE ''
        END AS verified,
        NULL as media1, NULL as media2, NULL as media3, NULL as media4, NULL as media5,
        reviews.id, products.name
SQL
    end
  end  
end

module Export
  class QuestionsCsvExport
    attr_reader :questions, :timezone

    CSV_HEADERS = %w[product_id question customer_name customer_email answer status question_date verified id product_name].freeze

    def initialize(questions: Question.all, timezone: Time.zone)
      @questions = questions
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
      query = questions.joins(:product)
                       .joins(:customer)
                       .joins("LEFT OUTER JOIN comments ON comments.commentable_id = questions.id AND comments.commentable_type = 'Question'")
                       .order("questions.id ASC")
      data = query.pluck(pluck_query)

      model = questions.model

      keys = CSV_HEADERS.map(&:to_sym)
      data.map do |row|
        hash = keys.zip(row).to_h

        hash[:id] = model.encode_id hash[:id]
        hash[:created_at] = hash[:created_at]&.in_time_zone(timezone)
        hash.values
      end
    end

    def pluck_query
      <<SQL
          products.id_from_provider, questions.body,
          customers.name, customers.email,
          COALESCE(comments.body, '') AS comment_body, questions.status, questions.created_at,
          questions.verification AS verified,
          questions.id, products.name
SQL
    end

  end
end

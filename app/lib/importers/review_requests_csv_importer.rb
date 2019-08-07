module Importers
  class ReviewRequestsCsvImporter
    attr_reader :store

    IMPORT_REVIEW_REQUEST_FIELDS = OpenStruct.new(product_ids_field:    'product_ids',
                                                  customer_name_field:  'customer_name',
                                                  customer_email_field: 'customer_email',
                                                  scheduled_for_field:  'scheduled_for').freeze

    REQUIRED_REVIEW_REQUEST_FIELDS = %w[product_ids customer_email].freeze

    delegate :product_ids_field, :customer_name_field, :customer_email_field, :scheduled_for_field,
             to: :IMPORT_REVIEW_REQUEST_FIELDS

    def initialize(store)
      @store = store
    end

    def self.valid?(column_names)
      (REQUIRED_REVIEW_REQUEST_FIELDS - column_names).empty?
    end

    def import(csv)
      Searchkick.callbacks(false) do
        csv.reverse_each.map do |review_request_data|
          import_row review_request_data
        end.compact
      end
    end

    def import_row(row_data)
      product_ids    = row_data[product_ids_field]
      customer_name  = row_data[customer_name_field]
      customer_email = row_data[customer_email_field]
      scheduled_for  = row_data[scheduled_for_field]
      scheduled_for  = '' if scheduled_for.blank?

      if product_ids.present?
        products = product_ids.split(' ').map(&:strip).map do |product_id|
          @store.products.find_by id_from_provider: product_id
        end
      else
        products = []
      end

      if products.any?{ |e| e.nil? }
        return row_data
      end
      
      customer = @store.customers.where(email: customer_email).first

      if customer.present?
        customer.update name: customer_name, skip_reindex_children: true
      elsif customer_email.present?
        customer = Customer.create store_id:              @store.id,
                                   email:                 customer_email,
                                   name:                  customer_name,
                                   id_from_provider:      customer_email,
                                   skip_reindex_children: true
      end

      return row_data if customer.blank? || !customer.valid?

      begin
        scheduled_for = DateTime.parse(scheduled_for)
      rescue ArgumentError
        scheduled_for = DateTime.current
      end

      imported_review_request = ImportedReviewRequest.new(customer: customer, scheduled_for: scheduled_for)

      products.each do |product|
        imported_review_request.products << product
      end

      imported_review_request.save ? nil : row_data
    end
  end
end

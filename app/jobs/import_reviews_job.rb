class ImportReviewsJob < ApplicationJob
  queue_as :default

  ### SIDEKIQED

  def perform(store_id, csv, provider)
    store = Store.find_by_id(store_id)
    return unless store.present?

    Time.zone = store.time_zone
    unimported_rows = Array.new

    provider ||= :default
    case provider.to_sym
      when :yotpo
        csv = YotpoReviewsParser.parse(csv)
    end

    product_id_field     = Upload::IMPORT_REVIEW_FIELDS[:default][:product_id_field]
    rating_field         = Upload::IMPORT_REVIEW_FIELDS[:default][:rating_field]
    feedback_field       = Upload::IMPORT_REVIEW_FIELDS[:default][:feedback_field]
    customer_name_field  = Upload::IMPORT_REVIEW_FIELDS[:default][:customer_name_field]
    customer_email_field = Upload::IMPORT_REVIEW_FIELDS[:default][:customer_email_field]
    comment_field        = Upload::IMPORT_REVIEW_FIELDS[:default][:comment_field]
    status_field         = Upload::IMPORT_REVIEW_FIELDS[:default][:status_field]
    review_date_field    = Upload::IMPORT_REVIEW_FIELDS[:default][:review_date_field]
    verified_field       = Upload::IMPORT_REVIEW_FIELDS[:default][:verified_field]

    Customer.skip_callback(:commit, :after, :reindex_children)
    Product.skip_callback(:commit, :after, :reindex_children)
    Searchkick.callbacks(false) do
      csv.reverse_each do |review_data|
        product        = store.products.find_by_id_from_provider(review_data[product_id_field])
        rating         = review_data[rating_field]
        feedback       = review_data[feedback_field]
        customer_name  = review_data[customer_name_field]
        customer_email = review_data[customer_email_field]
        comment        = review_data[comment_field]
        status         = review_data[status_field]
        status         = ImportedReview.statuses[:pending] unless ImportedReview.statuses.keys.include?(status)
        review_date    = review_data[review_date_field]
        review_date    = '' unless review_date.present?

        customer = store.customers.where(email: customer_email).first
        if customer.present?
          customer.update_attributes(name: customer_name)
        else
          customer = Customer.create(store_id:         store.id,
                                     email:            customer_email,
                                     name:             customer_name,
                                     id_from_provider: customer_email) if customer_email.present?
        end

        begin
          review_date = DateTime.parse(review_date)
        rescue ArgumentError
          review_date = nil
        end

        unless product.present? && rating.present? && (rating.is_a?(Numeric) || rating.is_number?) && feedback.present? && customer.present? && customer.persisted? && review_date.present? && review_date <= DateTime.current
          unimported_rows << review_data
          next
        end

        imported_review = ImportedReview.new(product:     product,
                                             rating:      rating,
                                             feedback:    feedback,
                                             customer:    customer,
                                             comment:     comment,
                                             status:      status,
                                             review_date: review_date,
                                             verified:    review_data[verified_field].present? && review_data[verified_field].downcase == 'yes')

        unimported_rows << review_data unless imported_review.save

      end

      unless unimported_rows.empty?
        unimported_csv = CSV.generate do |csv|
          unimported_rows = YotpoReviewsParser.parse_to_yotpo(unimported_rows) if provider.to_sym == :yotpo
          csv << unimported_rows.first.keys
          unimported_rows.reverse_each {|row| csv << row.values}
        end
        BackMailer.unimported_reviews(store.user.id, unimported_csv, "failed_reviews_import_#{ DateTime.current.to_i }.csv", csv.count, unimported_rows.count).deliver!
        # TODO notify about not imported rows in back

      end
    end
    Product.set_callback(:commit, :after, :reindex_children)
    Customer.set_callback(:commit, :after, :reindex_children)
    store.reindex_children

    store.settings(:background_workers).update_attributes(reviews_seed_running: false)
    store.settings(:background_workers).update_attributes(reviews_seeded: true)
    if csv.count == unimported_rows.count
      ActionCable.server.broadcast "onboarding-#{store.user.hashid}",
                                   {view: ApplicationController.renderer.render(partial: 'back/imported_reviews/failed',
                                                                                locals: { store: store }),
                                    object: 'imported-reviews'}
    else
      ActionCable.server.broadcast "onboarding-#{store.user.hashid}",
                                   {view: ApplicationController.renderer.render(partial: 'back/imported_reviews/ready',
                                                                                locals: { store: store }),
                                    object: 'imported-reviews'}
    end
  end
end

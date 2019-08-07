class BulkRequestJob < ApplicationJob
  queue_as :default

  ### SIDEKIQED

  def perform(store_id, csv)
    store = Store.find_by_id(store_id)
    return unless store.present?

    Time.zone = store.time_zone
    unimported_rows = Array.new

    product_ids_field    = Upload::IMPORT_REVIEW_REQUEST_FIELDS[:product_ids_field]
    customer_name_field  = Upload::IMPORT_REVIEW_REQUEST_FIELDS[:customer_name_field]
    customer_email_field = Upload::IMPORT_REVIEW_REQUEST_FIELDS[:customer_email_field]
    scheduled_for_field  = Upload::IMPORT_REVIEW_REQUEST_FIELDS[:scheduled_for_field]

    Customer.skip_callback(:commit, :after, :reindex_children)
    Product.skip_callback(:commit, :after, :reindex_children)
    Searchkick.callbacks(false) do
      csv.reverse_each do |review_request_data|
        product_ids = review_request_data[product_ids_field]
        products = []
        product_ids.split(' ').map(&:strip).each do |product_id|
          product = store.products.find_by_id_from_provider(product_id)
          products << product unless product.blank?
        end

        customer_name  = review_request_data[customer_name_field]
        customer_email = review_request_data[customer_email_field]
        scheduled_for  = review_request_data[scheduled_for_field]
        scheduled_for  = '' unless scheduled_for.present?

        customer = store.customers.where(email: customer_email).first
        if customer.present?
          customer.update_attributes(name: customer_name)
        else
          customer = Customer.create(store_id:         store.id,
                                     email:            customer_email,
                                     name:             customer_name,
                                     id_from_provider: customer_email) if customer_email.present?
        end

        if products.empty? || customer.blank? || !customer.valid?
          unimported_rows << review_request_data
          next
        end

        begin
          scheduled_for = DateTime.parse(scheduled_for)
        rescue ArgumentError
          scheduled_for = DateTime.current
        end

        imported_review_request = ImportedReviewRequest.new(customer: customer, scheduled_for: scheduled_for)
        products.each do |product|
          imported_review_request.products << product
        end
        unimported_rows << review_request_data unless imported_review_request.save
      end

      unless unimported_rows.empty?
        unimported_csv = CSV.generate do |csv|
          csv << unimported_rows.first.keys
          unimported_rows.reverse_each {|row| csv << row.values}
        end
        BackMailer.unimported_review_requests(store.user.id, unimported_csv, "failed_requests_import_#{ DateTime.current.to_i }.csv", csv.count, unimported_rows.count).deliver!
        # TODO notify about not imported rows in back
      end
    end
    Product.set_callback(:commit, :after, :reindex_children)
    Customer.set_callback(:commit, :after, :reindex_children)
    store.reindex_children

    store.settings(:background_workers).update_attributes(review_requests_seed_running: false)
    store.settings(:background_workers).update_attributes(review_requests_seeded: true)
    if csv.count == unimported_rows.count
      ActionCable.server.broadcast "onboarding-#{store.user.hashid}",
                                   {view: ApplicationController.renderer.render(partial: 'back/imported_review_requests/failed',
                                                                                locals: { store: store }),
                                    object: 'imported-review-requests'}
    else
      ActionCable.server.broadcast "onboarding-#{store.user.hashid}",
                                   {view: ApplicationController.renderer.render(partial: 'back/imported_review_requests/ready',
                                                                                locals: { store: store }),
                                    object: 'imported-review-requests'}
    end
  end
end

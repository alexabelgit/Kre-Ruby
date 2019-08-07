class ImportQuestionsWorker
  include Sidekiq::Worker

  sidekiq_options queue: :default

  def perform(store_id, csv)
    store = Store.find_by id: store_id
    return if store.blank?

    Time.zone = store.time_zone
    unimported_rows = Array.new

    product_id_field     = Upload::IMPORT_QUESTION_FIELDS[:product_id_field]
    question_field       = Upload::IMPORT_QUESTION_FIELDS[:question_field]
    customer_name_field  = Upload::IMPORT_QUESTION_FIELDS[:customer_name_field]
    customer_email_field = Upload::IMPORT_QUESTION_FIELDS[:customer_email_field]
    answer_field         = Upload::IMPORT_QUESTION_FIELDS[:answer_field]
    status_field         = Upload::IMPORT_QUESTION_FIELDS[:status_field]
    question_date_field  = Upload::IMPORT_QUESTION_FIELDS[:question_date_field]
    verified_field       = Upload::IMPORT_QUESTION_FIELDS[:verified_field]

    Searchkick.callbacks(false) do
      csv.reverse_each do |question_data|
        product        = store.products.find_by_id_from_provider(question_data[product_id_field])
        body           = question_data[question_field]
        customer_name  = question_data[customer_name_field]
        customer_email = question_data[customer_email_field]
        answer         = question_data[answer_field]
        status         = question_data[status_field]
        status         = Question.statuses[:pending] unless Question.statuses.key?(status)
        question_date  = question_data[question_date_field]
        question_date  = '' unless question_date.present?

        customer = store.customers.where(email: customer_email).first
        if customer.present?
          customer.update_attributes(name: customer_name, skip_reindex_children: true)
        else
          customer = Customer.create(store_id:              store.id,
                                     email:                 customer_email,
                                     name:                  customer_name,
                                     id_from_provider:      customer_email,
                                     skip_reindex_children: true) if customer_email.present?
        end

        unless product.present? && body.present? && customer.present?
          unimported_rows << question_data
          next
        end

        begin
          question_date = DateTime.parse(question_date)
        rescue ArgumentError
          question_date = DateTime.current
        end


        imported_question = ImportedQuestion.new(customer:     customer,
                                                 product:      product,
                                                 body:         body,
                                                 status:       status,
                                                 submitted_at: question_date,
                                                 answer:       answer,
                                                 verified:     question_data[verified_field].present? && question_data[verified_field].downcase == 'yes')

        unimported_rows << question_data unless imported_question.save
      end

      unless unimported_rows.empty?
        FailedImportUploader.new(store).unimported_questions(unimported_rows)
        BackMailer.unimported_questions(store.user_id, csv.count, unimported_rows.count).deliver
      end
    end
    store.reindex_children

    store.update_settings :background_workers,
                          questions_seed_running: false,
                          questions_seeded: true
    broadcast_result store, ready: csv.count != unimported_rows.count
  end

  private

  def broadcast_result(store, ready:)
    broadcaster = OnboardingBroadcaster.new(store)
    message = ready ? 'ready' : 'failed'
    template = "back/imported_questions/#{message}"
    broadcaster.broadcast template, 'imported-questions'
  end
end

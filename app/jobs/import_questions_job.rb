class ImportQuestionsJob < ApplicationJob
  queue_as :default

  ### SIDEKIQED

  def perform(store_id, csv)
    store = Store.find_by_id(store_id)
    return unless store.present?

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

    Customer.skip_callback(:commit, :after, :reindex_children)
    Product.skip_callback(:commit, :after, :reindex_children)
    Searchkick.callbacks(false) do
      csv.reverse_each do |question_data|
        product        = store.products.find_by_id_from_provider(question_data[product_id_field])
        body           = question_data[question_field]
        customer_name  = question_data[customer_name_field]
        customer_email = question_data[customer_email_field]
        answer         = question_data[answer_field]
        status         = question_data[status_field]
        status         = Question.statuses[:pending] unless Question.statuses.keys.include?(status)
        question_date  = question_data[question_date_field]
        question_date  = '' unless question_date.present?

        customer = store.customers.where(email: customer_email).first
        if customer.present?
          customer.update_attributes(name: customer_name)
        else
          customer = Customer.create(store_id:         store.id,
                                     email:            customer_email,
                                     name:             customer_name,
                                     id_from_provider: customer_email) if customer_email.present?
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
        unimported_csv = CSV.generate do |csv|
          csv << unimported_rows.first.keys
          unimported_rows.reverse_each { |row| csv << row.values }
        end
        BackMailer.unimported_questions(store.user.id, unimported_csv, "failed_qa_import_#{ DateTime.current.to_i }.csv", csv.count, unimported_rows.count).deliver!
        # TODO notify about not imported rows in back
      end
    end
    Product.set_callback(:commit, :after, :reindex_children)
    Customer.set_callback(:commit, :after, :reindex_children)
    store.reindex_children

    store.settings(:background_workers).update_attributes(questions_seed_running: false)
    store.settings(:background_workers).update_attributes(questions_seeded: true)
    if csv.count == unimported_rows.count
      ActionCable.server.broadcast "onboarding-#{store.user.hashid}",
                                   {view: ApplicationController.renderer.render(partial: 'back/imported_questions/failed',
                                                                                locals: { store: store }),
                                    object: 'imported-questions'}
    else
      ActionCable.server.broadcast "onboarding-#{store.user.hashid}",
                                   {view: ApplicationController.renderer.render(partial: 'back/imported_questions/ready',
                                                                                locals: { store: store }),
                                    object: 'imported-questions'}
    end
  end
end

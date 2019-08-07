module Maintenance
  class ReviewsAndQuestionsMigrationService
    attr_reader :store, :new_store

    def initialize(store, new_store: nil)
      @store = store
      @new_store = new_store
    end

    def move_reviews(old_product, new_product, mark_as_migrated: true)
      reviews_to_migrate = old_product.reviews.where(migrated: false)
      ActiveRecord::Base.no_touching do
        migrated_reviews = reviews_to_migrate.map do |existing_review|
          new_review = create_review existing_review, new_product
          next unless new_review.valid?

          migrate_comment(new_review, existing_review)
          migrate_media new_review, existing_review
          existing_review
        end

        old_product.reviews.where(id: migrated_reviews).update(migrated: true) if mark_as_migrated

        # return not migrated reviews
        reviews_to_migrate.where.not(id: migrated_reviews).pluck(:id)
      end
    end

    def move_questions(old_product, new_product, mark_as_migrated: true)
      questions_to_migrate = old_product.questions.where(migrated: false)
      ActiveRecord::Base.no_touching do
        migrated_questions = questions_to_migrate.map do |existing_question|
          new_question = create_question existing_question, new_product
          next unless new_question

          migrate_comment(new_question, existing_question)
          existing_question
        end

        old_product.questions.where(id: migrated_questions).update(migrated: true) if mark_as_migrated

        # return not migrated questions
        questions_to_migrate.where.not(id: migrated_questions).pluck(:id)
      end

    end

    private

    def create_review(existing_review, new_product)
      params = build_review_params existing_review, new_product
      outcome = Reviews::CreateReview.run params
      outcome.result
    end

    def create_question(existing_question, new_product)
      params = build_question_params existing_question, new_product
      Question.create params
    end

    def build_question_params(existing_question, new_product)
      params = existing_question.slice(:body, :status, :verification, :votes_count)
      params[:submitted_at] = existing_question.submitted_at.to_datetime
      if existing_question.customer.present?
        new_customer = create_new_customer existing_question.customer
        params[:customer] = new_customer if new_customer.valid?
      end
      params[:product] = new_product
      params
    end

    def migrate_comment(new_commentable, old_commentable)
      existing_comment = old_commentable.comment
      return unless existing_comment.present?
      if new_commentable.nil?
        return
      end
      Comment.create commentable:           new_commentable,
                     body:                  existing_comment.body,
                     user:                  new_store.user,
                     display_name:          new_store.settings(:agents).default_name
    end

    def migrate_media(new_review, existing_review)
      existing_review.media.each do |medium|
        medium.migrate_to_review!(new_review, skip_cloudinary_and_recognition: Rails.env.development?)
        existing_review.reload
      end
    end

    def build_review_params(existing_review, new_product)
      params = existing_review.slice(:rating, :feedback, :comment, :votes_count, :status,
                                     :review_date, :verification, :source, :publish_date)
      params[:review_date] = existing_review.review_date.to_datetime
      params[:publish_date] = existing_review.review_date.to_datetime
      params[:product] = new_product
      params[:reviewables] = [new_product]

      if existing_review.customer.present?
        new_customer = create_new_customer existing_review.customer
        params[:customer] = new_customer if new_customer.valid?
      end
      params[:store] = new_store

      params
    end

    def create_new_customer(old_customer)
      params = old_customer.slice(:email, :name, :id_from_provider).merge(store_id: new_store.id)
      Customer.find_or_create_by params
    end
  end
end
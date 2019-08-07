module Reviews
  class CreateReview < ApplicationCommand

    object    :customer,         default: nil
    object    :transaction_item, default: nil

    array :reviewables, default: [] do
      object
    end

    string    :feedback
    integer   :rating
    string    :title,            default: nil
    symbol    :source,           default: :manual
    symbol    :status,           default: :pending
    date_time :review_date,      default: nil
    date_time :publish_date,     default: nil
    symbol    :verification,     default: :unverified

    hash :media_attributes, default: nil, strip: false

    # Additional inputs

    object    :store,                 default: nil
    string    :customer_email,        default: nil
    string    :customer_name,         default: nil
    boolean   :skip_reindex_children, default: false

    def execute
      review = Review.new

      ActiveRecord::Base.transaction do
        raise ActiveRecord::Rollback unless set_missing_inputs

        params            = inputs.except(:customer_email,
                                          :customer_name,
                                          :reviewables,
                                          :store)
        params            = params.except(:media_attributes) if media_attributes.blank?
        review.attributes = params

        set_reviewables(review)
        review_request = @transaction_item.review_request if @transaction_item.present?
        verify_review(review, review_request)
        incentivise_review(review, review_request)
        review.feedback = review.feedback.mask_email

        raise ActiveRecord::Rollback unless review.save

        set_review_request_status(review_request)
        review.published! if review.can_auto_publish?
        @publish_date = DateTime.current unless @publish_date.present?
        review.update_attributes(publish_date: @publish_date) if review.published?
      end

      call_after_commit_methods(review) if review.persisted?
      merge_errors(review)

      review
    end

    private

    def set_missing_inputs
      if @customer.blank? && @store.present?
        @customer = Customer.generate_by_email(@store, @customer_email, @customer_name)
      end

      if @transaction_item.present?
        @customer     = @transaction_item.customer   unless @customer.present?
        @reviewables << @transaction_item.reviewable unless @reviewables.any?
      elsif @reviewables.any?
        @transaction_item = @customer.transaction_items.left_outer_joins(:review).where(reviewable: @reviewables).where(reviews: { id: nil }).first if @customer.present?
      end

      unless @customer&.valid?.to_b
        self.errors.add(:customer, I18n.t('activerecord.errors.models.review.attributes.customer.must_be_authenticated'))
        return false
      end

      @store = @customer.store unless @store.present?

      @review_date  = DateTime.current unless @review_date.present?

      return true
    end

    def set_reviewables(review)
      @reviewables.each do |reviewable|
        review.review_reviewables << ReviewReviewable.new(reviewable: reviewable)
      end
    end

    def verify_review(review, review_request)
      if review_request.present? && review_request.review_verifiable?
        if review_request.from_provider?
          review.verification = :verified_by_provider
          review.source       = :from_provider        if @source == :manual
        else
          review.verification = :verified_by_merchant
          review.source       = :manual               if @source == :from_provider
        end
      end
    end

    def incentivise_review(review, review_request)
      if review_request.present?
        review.with_incentive = review_request.with_incentive
      end
    end

    def set_review_request_status(review_request)
      if review_request.present?
        review_request_status = :complete

        review_request.transaction_items.with_unsuppressed_products.where.not(id: @transaction_item.id).each do |transaction_item|
          review_request_status = :incomplete if transaction_item.review.blank?
        end

        review_request.update_attributes(status: review_request_status)
        review_request.update_attributes(scheduled_for: nil) if review_request.complete?
      end
    end

    def call_after_commit_methods(review)
      review.followup
      review.reindex_children unless @skip_reindex_children
      review.shopify_sync
      review.product.questions.where(customer: review.customer).map(&:verify) if review.product.present? && review.verified_by_merchant? && review.transaction_item.blank?
      review.check_for_abuse
    end

    def merge_errors(review)
      errors.merge!(review.errors)
      review.errors.clear
      review.errors.merge!(errors)
    end

  end
end

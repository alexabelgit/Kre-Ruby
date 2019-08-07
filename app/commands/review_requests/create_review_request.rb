module ReviewRequests
  class CreateReviewRequest < ApplicationCommand
    object    :customer,      default: nil
    date_time :scheduled_for, default: nil
    symbol    :status,        default: :scheduled

    object :order, default: nil

    array :transaction_items, default: [] do
      object
    end

    array :product_ids, default: [] do
      integer
    end

    object :business, class: Store, default: nil

    # Additional inputs

    object    :store,                 default: nil
    string    :customer_email,        default: nil
    string    :customer_name,         default: nil

    def execute
      review_request = ReviewRequest.new

      ActiveRecord::Base.transaction do
        raise ActiveRecord::Rollback unless set_missing_inputs

        review_request.attributes = inputs.except(:customer_email,
                                                  :customer_name,
                                                  :product_ids,
                                                  :transaction_items,
                                                  :business,
                                                  :store)
        raise ActiveRecord::Rollback unless set_transaction_items(review_request)
        raise ActiveRecord::Rollback unless review_request.save
      end
      call_after_commit_methods(review_request) if review_request.persisted?
      merge_errors(review_request)

      review_request
    end

    private

    def set_missing_inputs
      @customer = Customer.generate_by_email(@store, @customer_email, @customer_name) if @customer.blank? && @store.present?
      @customer = @transaction_items.first.customer if @transaction_items.any? && @customer.blank?
      unless @customer.present?
        self.errors.add(:customer, "can't be blank")
        return false
      end
      @store = @customer.store unless @store.present?

      unless @transaction_items.any?
        @product_ids.each do |product_id|
          product = @store.products.find_by_id(product_id)
          @transaction_items << TransactionItem.new(reviewable: product, customer: @customer) if product.present?
        end
        @transaction_items << TransactionItem.new(reviewable: @business, customer: @customer) if @business.present?
      end

      return true
    end

    def set_transaction_items(review_request)
      unless @transaction_items.any?
        self.errors.add(:transaction_items, "can't be blank")
        return false
      end
      @transaction_items.each do |transaction_item|
        review_request.transaction_items << transaction_item
      end
      true
    end

    def call_after_commit_methods(review_request)
      @order.review_request = review_request if @order.present?
      review_request.order  = @order         if @order.present?
      SendReviewRequestWorker.perform_at(@scheduled_for, review_request.id, ReviewRequest.name) if @scheduled_for.present?
    end

    def merge_errors(review_request)
      errors.merge!(review_request.errors)
      review_request.errors.clear
      review_request.errors.merge!(errors)
    end

  end
end

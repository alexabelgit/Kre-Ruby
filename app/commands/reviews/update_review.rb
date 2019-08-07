module Reviews
  class UpdateReview < ApplicationCommand
    object  :review
    symbol  :status,         default: nil
    boolean :with_incentive, default: nil

    boolean :skip_reindex_children, default: false

    def execute
      updated = ActiveRecord::Base.transaction do
        if status.present?
          raise ActiveRecord::Rollback unless updatable_to_status?
          attributes = { status: status }
          attributes[:publish_date] = DateTime.current if !review.published? && status == :published
        elsif !with_incentive.nil?
          attributes = { with_incentive: with_incentive }
        end
        review.update!(attributes)
      end

      call_after_commit_methods(review) if updated
      merge_errors(review)

      review
    end

    private

    def updatable_to_status?
      Review.statuses_updatable_to.include? status.to_s
    end

    def call_after_commit_methods(review)
      review.review_reviewables.each(&:touch)
      review.reindex_children unless skip_reindex_children
      review.shopify_sync
    end

    def merge_errors(review)
      errors.merge!(review.errors)
      review.errors.clear
      review.errors.merge!(errors)
    end
  end
end

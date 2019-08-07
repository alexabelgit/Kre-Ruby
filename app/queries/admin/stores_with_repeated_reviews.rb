module Admin
  class StoresWithRepeatedReviews
    attr_reader :initial_scope

    def initialize(initial_scope = Store.all)
      @initial_scope = initial_scope
    end

    def call
      store_ids = Customer.joins(reviews: :review_reviewables)
                          .where("review_reviewables.reviewable_type = 'Product'")
                          .group('customers.id', 'review_reviewables.reviewable_id')
                          .having('COUNT(reviews.id) > 1')
                          .pluck('customers.store_id')
      initial_scope.where(id: store_ids)
    end

  end
end
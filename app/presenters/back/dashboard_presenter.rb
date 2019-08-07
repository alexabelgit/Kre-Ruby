module Back
  class DashboardPresenter
    attr_reader :store, :view

    attr_reader :pending_reviews_count, :pending_questions_count,
                :abuse_reports_count, :reviewed_products_count,
                :reviews, :questions_count, :answered_questions_count

    delegate :onboarded?, :onboarding, :products_count, to: :store

    def initialize(store, view = ActionView::Base.new)
      @store = store
      @view = view

      @reviews = store.reviews

      @reviewed_products_count = store.products.reviewed.count
      @questions_count = store.questions.count
      @answered_questions_count = store.questions.answered.count

      @pending_reviews_count = store.reviews.pending.count
      @pending_questions_count = store.questions.pending.count
      @abuse_reports_count = store.abuse_reports.open.count
    end

    def sent_review_requests
      store.review_requests.where.not(status: [0, 4]).count
    end

    def pending_review_requests
      store.review_requests.pending.count
    end

    def top_rated_products
      Product.by_top_rating(store: store, dir: :desc, limit: 5)
    end

    def lowest_rated_products
      Product.by_top_rating(store: store, dir: :asc, limit: 5)
    end

    def published_reviews
      reviews.published
    end

    def reviews_count
      reviews.count
    end

    def unanswered_questions_count
      questions_count - answered_questions_count
    end

    def products_select_options
      Rails.cache.fetch [store, 'products-select-options', products_count ] do
        view.options_for_select store.products.a24z.pluck(:name, :id)
      end
    end

    def abuse_reports?
      abuse_reports_count.positive?
    end

    def pending_items?
      pending_questions? || pending_reviews?
    end

    def pending_questions?
      pending_questions_count.positive?
    end

    def pending_reviews?
      pending_reviews_count.positive?
    end

    def without_reviews
      products_count - reviewed_products_count
    end


  end
end
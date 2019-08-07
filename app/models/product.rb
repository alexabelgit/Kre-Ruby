class Product < ApplicationRecord
  include Filterable
  include Reviewable

  ## Callbacks
  after_create    :complete_onboarding_step
  after_save      :check_suppression
  before_create   :reindex_children, on: :create
  after_commit    :reindex_children
  after_commit    :sync_shopify_metafields, on: [:create]
  after_touch     :touch_products_in_same_group

  ## Associations
  belongs_to :store, touch: true, counter_cache: true

  has_many :individual_questions, class_name: Question.name, dependent: :destroy

  has_many :transaction_items,  as:      :reviewable,         dependent:  :destroy, inverse_of: :reviewable
  has_many :orders,             through: :transaction_items
  has_many :review_reviewables, as:      :reviewable,         dependent:  :destroy, inverse_of: :reviewable
  has_many :individual_reviews, through: :review_reviewables, source: :review, dependent: :destroy
  has_many :review_requests,    through: :transaction_items

  has_many :product_group_products
  has_many :groups, through: :product_group_products, source: :product_group

  has_many :grouped_products, class_name: Product.name, through: :groups, source: :products
  has_many :reviews_from_groups,   -> { distinct }, class_name: Review.name,   through: :grouped_products, source: :individual_reviews
  has_many :questions_from_groups, -> { distinct }, class_name: Question.name, through: :grouped_products, source: :individual_questions

  has_many :imported_reviews,   dependent: :destroy
  has_many :imported_questions, dependent: :destroy

  has_many :imported_review_request_products,  dependent: :destroy
  has_many :imported_review_requests,          through:   :imported_review_request_products

  ## Scopes
  scope :reviewed,      -> { joins(:individual_reviews).distinct(:product) }
  scope :questioned,    -> { joins(:individual_questions).distinct(:product) }
  scope :a24z,          -> (dir = :asc) { order(name: dir) }
  scope :unsuppressed,  -> { where(suppressed: false) }
  scope :suppressed,    -> { where(suppressed: true) }
  scope :with_outdated_metafields, -> { joins(:store).merge(Store.shopify).where("(products.updated_at - products.shopify_metafields_synced_at) > INTERVAL'1 hour'") }

  ## Enums
  enum storefront_availability: [:enabled, :disabled], _suffix: :on_site
  enum status: {  active:   0,
                  archived: 1,
                  hidden:   2 }

  searchkick word_start:  [:name], highlight: [:name],
             callbacks:   false

  # still need some way to counter cache reviews/questions counts
  scope :search_import, -> {
    includes(:individual_questions, :individual_reviews)
      .includes(:reviews_from_groups, :questions_from_groups)
  }

  # Attribute methods
  attr_accessor :skip_reindex_children

  def search_data
    {
      id_from_provider:   id_from_provider,
      name:               name,
      rating:             rating.to_f,
      reviews_count:      reviews_count,
      questions_count:    questions_count,
      status:             status,
      product_group_ids:  product_group_products.any? ? product_group_products.map{ |pgp| pgp.product_group_id} : nil,
      store_id:           store_id
    }
  end

  def self.by_top_rating(store:, dir: :desc, limit: 10)
    filter_params = { reviews_count: { gt: 0 } }
    filtered current_store: store,
             filter_params: filter_params,
             sort: { by_rating: dir },
             limit: limit
  end

  def self.search_fields
    [:name, { status: :exact }, { id_from_provider: :exact }]
  end

  def self.sort_mapper
    {
      by_rating:       { rating:          :dir },
      reviews_count:   { reviews_count:   :dir },
      questions_count: { questions_count: :dir },
      a24z:            { name:            :dir }
    }
  end

  mount_uploader :featured_image, FeaturedImageUploader
  mount_uploader :synced_image_backup, FeaturedImageUploader

  validates :id_from_provider, uniqueness: { scope: :store_id }
  validates :name, presence: true

  def has_groups?
    groups.any?
  end

  def reviews
    grouped_products.any? ? reviews_from_groups : individual_reviews
  end

  def questions
    grouped_products.any? ? questions_from_groups : individual_questions
  end

  def recent_reviews(page: 1, per_page: 10)
    Rails.cache.fetch [self, 'recent_reviews', page, per_page] do
      reviews.published.latest.paginate(page: page, per_page: per_page).includes(:comment, :customer, :products, :media)
    end
  end

  def recent_questions(page: 1, per_page: 10)
    Rails.cache.fetch [self, 'recent_questions', page, per_page] do
      questions.published.latest.paginate(page: page, per_page: per_page).includes(:comment, :customer, :product)
    end
  end

  def rating
    Rails.cache.fetch [self, 'rating'] do
      rating = reviews.published.average(:rating)
      rating.present? ? rating.round(1) : 0
    end
  end

  def individual_rating
    Rails.cache.fetch [self, 'individual_reviews_rating'] do
      rating = individual_reviews.published.average(:rating)
      rating.present? ? rating.round(1) : 0
    end
  end

  def reviews_count
    Rails.cache.fetch [self, 'published_reviews_count'] do
      reviews.published.count
    end
  end

  def has_reviews?
    reviews_count.positive?
  end

  def questions_count
    Rails.cache.fetch [self, 'published_questions_count'] do
      questions.published.count
    end
  end

  def seo_friendly_url
    # TODO: somehow mark that ugliness is for ecwid only, so that when we have
    # other platforms as well, we don't use this method for sharing their pages
    "http://store#{store.id_from_provider}.ecwid.com/sharer?ownerid=#{store.id_from_provider}&productid=#{id_from_provider}#_=_"
  end

  def rating_data
    Rails.cache.fetch [self, 'rating-data'] do
      reviews.published.rating_data
    end
  end

  def json_ld
    Rails.cache.fetch [self, 'json_ld']
    {
      '@context': 'http://schema.org',
      '@type':    'Product',
      name:       name,
      aggregateRating: {
        '@type':     'AggregateRating',
        bestRating:  5,
        ratingValue: rating,
        worstRating: 1,
        reviewCount: reviews_count
      },
      review: reviews.published.limit(12).map do |review|
        {
          '@type':       'Review',
          author:        review.display_name,
          datePublished: review.review_date,
          reviewBody:    review.feedback.excerpt,
          reviewRating: {
            '@type':     'Rating',
            bestRating:  5,
            ratingValue: review.rating,
            worstRating: 1
          }
        }
      end
    }
  end

  def after_suppression
    review_requests.incomplete.each do |review_request|
      review_request_status = review_request.transaction_items.with_unsuppressed_products.left_outer_joins(:review).where.not('transaction_items.reviewable_id = ? AND transaction_items.reviewable_type = ?', id, Product.name).where(reviews: {id: nil}) ? :incomplete : :complete
      review_request.update status: review_request_status
      review_request.update(scheduled_for: nil) if review_request.complete?
    end
  end

  def after_unsuppression
    review_requests.complete.each do |review_request|
      review_request.incomplete! if review_request.transaction_items.left_outer_joins(:review).where(reviewable_id: id, reviewable_type: Product.name).where(reviews: {id: nil}).any?
    end
  end

  def sync_shopify_metafields
    return unless store.shopify?
    SyncProductMetafieldsWorker.perform_async(store_id, id_from_provider)
  end

  def custom_image_allowed?
    !store.manages_products?
  end

  def custom_image?
    overwrite_featured_image
  end

  private

  def check_suppression
    return unless saved_change_to_suppressed?

    after_suppression if suppressed
    after_unsuppression unless suppressed
    sync_shopify_metafields if store.shopify?
  end

  def reindex_children
    return unless saved_changes.keys.length > 1 # when callback is caused by touch (only updated_at is changed) and there's nothing to reindex
    ReindexChildWorker.perform_async('Product', id)
    unless @skip_reindex_children
      ReindexChildWorker.perform_async('Review',        individual_reviews.pluck(:id)) if individual_reviews.any?
      ReindexChildWorker.perform_async('ReviewRequest', review_requests.pluck(:id))    if review_requests.any?
      ReindexChildWorker.perform_async('Question',      questions.pluck(:id))          if questions.any?
    end
    @skip_reindex_children = false
  end

  def complete_onboarding_step
    return if !store.custom? || store.settings(:onboarding).products_created.to_b
    store.update_settings(:onboarding, products_created: true)
  end

  def touch_products_in_same_group
    Product.no_touching do
      grouped_products.where.not(id: id).update updated_at: DateTime.current
      grouped_products.find_each do |grouped_product|
        grouped_product.sync_shopify_metafields
      end
    end
  end
end

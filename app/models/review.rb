class Review < ApplicationRecord
  require 'csv'
  require 'ostruct'

  include Filterable
  include ReadMore
  include Abusable

  REVIEWABLE_TYPES = {
    product:  Product.name,
    business: Store.name
  }.freeze

  after_commit    :reindex_children
  before_create   :reindex_children, on: :create

  belongs_to :customer,                            touch: true
  belongs_to :transaction_item, optional: true,    touch: true

  has_many :review_reviewables, dependent: :destroy, inverse_of: :review

  has_many :products,       through: :review_reviewables, source: :reviewable, source_type: Product.name
  has_many :businesses,     through: :review_reviewables, source: :reviewable, source_type: Store.name

  has_one :review_request, through: :transaction_item
  has_one :order,          through: :transaction_item

  has_many :emails,        as: :emailable,   dependent: :destroy
  has_one  :comment,       as: :commentable, dependent: :destroy
  has_many :social_posts,  as: :postable,    dependent: :destroy
  has_many :votes,         as: :votable,     dependent: :destroy
  has_many :flags,         as: :flaggable,   dependent: :destroy
  has_many :abuse_reports, as: :abusable,    dependent: :destroy

  has_many :media, -> { order(media_type: :desc, created_at: :asc) }, as: :mediable, dependent: :destroy

  accepts_nested_attributes_for :media

  ## Enums
  enum status:       [:pending,    :published,            :archived,            :suppressed]
  enum source:       [:manual,     :imported,             :from_provider,       :voluntary]
  enum verification: [:unverified, :verified_by_merchant, :verified_by_provider]

  delegate :store,        to: :customer
  delegate :user,         to: :store
  delegate :display_name, :display_first_name, :display_initials, to: :customer

  delegate :user_email, to: :store

  delegate :accepts_repeated_reviews?, :accepts_storefront_reviews?, to: :store, prefix: :store

  # Validations
  validates :rating, presence:  true
  validates :rating, inclusion: { in: 1..5 }

  validates :customer,           presence: true
  validates :review_reviewables, presence: true

  validates :feedback, presence: true
  validates :feedback, length:   { minimum: 1, maximum: 6000 }

  validates :transaction_item_id,  uniqueness:    { allow_nil: true }
  validate  :request_must_be_sent, on:            :create
  validate  :cannot_be_repeated,   unless:        :store_accepts_repeated_reviews?,   on: :create
  validate  :cannot_be_voluntary,  unless:        :store_accepts_storefront_reviews?, on: :create
  validates :review_date,          not_in_future: true

  scope :best,                       -> { order(rating: :desc) }
  scope :by_created_at,              -> { order(created_at: :desc) }
  scope :latest,                     -> { order(review_date: :desc) }
  scope :most_helpful,               -> { order("votes_count DESC") }
  scope :product_id,                 -> (product_id) { joins(:review_reviewables).where(review_reviewables: { reviewable_id: product_id, reviewable_type: Product.name }) }
  scope :rating,                     -> (rating) { where(rating: rating) }
  scope :requested,                  -> { joins(:transaction_item).where.not(transaction_items: {review_request_id: nil}) }
  scope :status,                     -> (status) { where(status: status) }
  scope :with_unsuppressed_products, -> { joins(:products).where(products: { suppressed: false }) }
  scope :with_media,                 -> { joins(:media).distinct(:review).where(media: {status: 'published'}) } # TODO: this does not work
  scope :with_social_posts,          -> { joins(:social_posts).distinct(:review) }
  scope :without_social_posts,       -> { left_outer_joins(:social_posts).where(social_posts: { postable_id: nil }).distinct(:review) }
  scope :worst,                      -> { order(rating: :asc) }
  scope :organic,                    -> { where(source: [:manual, :from_provider, :voluntary]) }

  searchkick word_start: [:feedback, :comment, :customer_email, :display_name, :product_name],
             highlight:  [:feedback, :comment, :customer_email, :display_name, :product_name],
             callbacks:  false

  scope :search_import, -> {
    includes(:comment)
      .includes(transaction_item: [
                  { product: [ :grouped_products,
                               { store: [ :setting_objects, :product_groups] }
                             ]
                  },
                  { order: { customer: { store: :setting_objects }}},
                  { review_request: { customer: { store: :setting_objects}}}
                ])
  }

  attr_accessor :skip_reindex_children

  def search_data
    {
      feedback:          feedback,
      comment:           comment.present? ? comment.body : nil,
      customer_email:    customer.email,
      display_name:      display_name,
      product_id:        product.present? ? product.id : nil,
      product_group_ids: products.any? ? (can_search_product_groups? ? products.select{ |product| product.groups.any? }.map{ |product| product.grouped_products.map(&:id)}.flatten : [product.id]) : nil,
      product_name:      product.present? ? product.name : nil,
      store_id:          store.id,
      rating:            rating,
      status:            status,
      review_date:       review_date,
      created_at:        created_at,
      helpfulness:       votes_count
    }
  end

  def self.search_fields
    [:feedback, :comment, :customer_email, :display_name, :product_name, { status: :exact }]
  end

  def self.sort_mapper
    {
      worst:         { rating:      { order: :asc,  unmapped_type: :long } },
      best:          { rating:      { order: :desc, unmapped_type: :long } },
      latest:        { review_date: { order: :desc, unmapped_type: :long } },
      most_helpful:  { helpfulness: { order: :desc, unmapped_type: :long } },
      by_created_at: { created_at:  { order: :desc, unmapped_type: :long } }
    }
  end

  def product
    products.first if products.any? # TODO ~ is it what we need?
  end

  def business
    businesses.first? if businesses.any?
  end

  def reviewables
    REVIEWABLE_TYPES.keys.map{ |reviewable_type| self.send(reviewable_type.to_s.pluralize) }.flatten
  end

  def reviewable
    reviewables.first
  end

  def verified?
    verified_by_merchant? || verified_by_provider?
  end

  def posted_on?(provider)
    social_posts.where(provider: SocialPost.providers[provider]).any?
  end

  def facebook_post_body
    store.settings(:reviews).facebook_post_template.parse_placeholders(Placeholders::REVIEW_FACEBOOK_POST, self, true)
  end

  def tweet_body
    store.settings(:reviews).tweet_template.parse_placeholders(Placeholders::REVIEW_TWEET, self, true).strip
  end

  def positive?
    rating >= 4
  end

  def critical?
    !positive?
  end

  def mood
    if positive?
      'positive'
    elsif critical?
      'critical'
    end
  end

  def media_collage?
    published_media.any? && store.media_reviews_enabled? && store.media_collage_in_social_posts?
  end

  def generate_media_collage
    GenerateMediaCollageWorker.perform_in(30.seconds, id) if media_collage?
  end

  def published_media
    media.published.with_cloudinary_id
  end

  def published_videos
    media.video.published.with_cloudinary_id
  end

  def published_images
    media.image.published.with_cloudinary_id
  end

  def media_collage
    if published_images.any?
      media = published_images
    elsif published_videos.any?
      media = published_videos.split(1).first # TODO: split is used because we need media to be array and to has a length of 1 so that it falls under when media.length == 1 case
    end

    return nil unless media

    dimensions = { width: 1212, height: 636 } # This now works with both twitter and facebook, but dimensions are coming from fb preferred aspect ratio
    gap        = 6                            # this is the pixel value for the gap between media collage items

    collage = case media.length
              when 1
                media.first.public_url(format: :jpg)
              when 2
                ApplicationController.helpers.cl_image_path(
                  media.first.cloudinary_public_id,
                  format: :jpg,
                  transformation: [
                    {
                      width:  dimensions[:width] / 2 - gap,
                      height: dimensions[:height],
                      crop:   "fill"
                    },
                    {
                      overlay: media.second.public_id_for_ovelay,
                      width:   dimensions[:width] / 2 - gap,
                      height:  dimensions[:height],
                      x:       dimensions[:width] / 2 + gap,
                      crop:    "fill"
                    }
                  ]
                )
              when 3
                ApplicationController.helpers.cl_image_path(
                  media.first.cloudinary_public_id,
                  format: :jpg,
                  transformation: [
                    {
                      width:  dimensions[:width] / 2 - gap,
                      height: dimensions[:height],
                      crop:   "fill"
                    },
                    {
                      overlay: media.second.public_id_for_ovelay,
                      width:   dimensions[:width]  / 2 - gap,
                      height:  dimensions[:height] / 2 - gap,
                      x:       dimensions[:width]  / 2 + gap,
                      y:       0,
                      crop:    "fill",
                      gravity: "north"
                    },
                    {
                      overlay: media.third.public_id_for_ovelay,
                      width:   dimensions[:width]  / 2 - gap,
                      height:  dimensions[:height] / 2 - gap,
                      x:       0,
                      y:       0,
                      crop:    "fill",
                      gravity: "south_east"
                    }
                  ]
                )
              when 4
                ApplicationController.helpers.cl_image_path(
                  media.first.cloudinary_public_id,
                  format: :jpg,
                  transformation: [
                    {
                      width:  dimensions[:width] / 2 - gap,
                      height: dimensions[:height],
                      crop:   "fill"
                    },
                    {
                      overlay: media.second.public_id_for_ovelay,
                      width:   dimensions[:width]  / 2 - gap,
                      height:  dimensions[:height] / 2 - gap,
                      x:       dimensions[:width]  / 2 + gap,
                      y:       0,
                      crop:    "fill",
                      gravity: "north"
                    },
                    {
                      overlay: media.third.public_id_for_ovelay,
                      width:   dimensions[:width]  / 4 - gap * 3 / 2,
                      height:  dimensions[:height] / 2 - gap,
                      x:       dimensions[:width]  / 2 + gap,
                      y:       0,
                      crop:    "fill",
                      gravity: "south_west"
                    },
                    {
                      overlay: media.fourth.public_id_for_ovelay,
                      width:   dimensions[:width]  / 4 - gap * 3 / 2,
                      height:  dimensions[:height] / 2 - gap,
                      x:       0,
                      y:       0,
                      crop:    "fill",
                      gravity: "south_east"
                    }
                  ]
                )
              else
                ApplicationController.helpers.cl_image_path(
                  media.first.cloudinary_public_id,
                  format: :jpg,
                  transformation: [
                    {
                      width:  dimensions[:width] / 2 - gap,
                      height: dimensions[:height],
                      crop:   "fill"
                    },
                    {
                      overlay: media.second.public_id_for_ovelay,
                      width:   dimensions[:width]  / 4 - gap * 3 / 2,
                      height:  dimensions[:height] / 2 - gap,
                      x:       dimensions[:width]  / 2 + gap,
                      y:       0,
                      crop:    "fill",
                      gravity: "north_west"
                    },
                    {
                      overlay: media.third.public_id_for_ovelay,
                      width:   dimensions[:width]  / 4 - gap * 3 / 2,
                      height:  dimensions[:height] / 2 - gap,
                      x:       dimensions[:width]  / 4 * 3 + gap * 3 / 2,
                      y:       0,
                      crop:    "fill",
                      gravity: "north_west"
                    },
                    {
                      overlay: media.fourth.public_id_for_ovelay,
                      width:   dimensions[:width]  / 4 - gap * 3 / 2,
                      height:  dimensions[:height] / 2 - gap,
                      x:       dimensions[:width]  / 2 + gap,
                      y:       0,
                      crop:    "fill",
                      gravity: "south_west"
                    },
                    {
                      overlay: media.fifth.public_id_for_ovelay,
                      width:   dimensions[:width]  / 4 - gap * 3 / 2,
                      height:  dimensions[:height] / 2 - gap,
                      x:       dimensions[:width]  / 4 * 3 + gap * 3 / 2,
                      y:       0,
                      crop:    "fill",
                      gravity: "south_west"
                    }
                  ]
                )
              end

    collage
  end

  def self.abusable_fields
    ['feedback']
  end

  def self.statuses_updatable_to
    %w[published archived]
  end

  def suppress
    suppressed!
  end

  def self.rating_data
    Rails.cache.fetch ['rating-data', all.cache_key] do
      all_ratings_hash = { 5 => 0, 4 => 0, 3 => 0, 2 => 0, 1 => 0 }
      grouped_ratings = group('reviews.rating').order('reviews.rating DESC')
                            .pluck('reviews.rating, COUNT(DISTINCT reviews.id)').to_h
      reviews_by_rating = all_ratings_hash.merge grouped_ratings
      total_reviews = count

      result = reviews_by_rating.map do |rating, reviews_count|
        percentage = reviews_count.percent_of(total_reviews)
        OpenStruct.new(rating: rating,
                       percentage: percentage,
                       count: reviews_count,
                       percentage_rounded: percentage.round)
      end

      total_rounded_value = result.sum(&:percentage_rounded)
      if total_rounded_value.positive?
        is_overhead = total_rounded_value > 100
        predicate = ->(x) { is_overhead ? x.percentage_rounded > x.percentage : x.percentage_rounded < x.percentage }
        sorted_results = result.select(&predicate).sort_by(&:percentage)
        (total_rounded_value - 100).abs.times do |i|
          diff = is_overhead ? -1 : 1
          sorted_results[i].percentage_rounded += diff
        end
      end
      result
    end
  end

  def self.to_csv(timezone = Time.zone)
    Export::ReviewsCsvExport.new(reviews: all, timezone: timezone).generate
  end

  def product_name
    product.name if product.present?
  end

  def business_name
    business.name if business.present?
  end

  def followup
    return if imported?

    sendable =
      if positive? && store.settings(:reviews).send_positive_review_followup_mail.to_b
        true
      elsif critical? && store.settings(:reviews).send_critical_review_followup_mail.to_b
        true
      else
        false
      end

    if sendable
      unless customer.suppressed?
        uid      = SecureRandom.uuid
        response = FrontMailer.send("#{mood}_review_follow_up", self, uid).deliver!
        emails.create(helpful_id: uid, 'smtp-id': response.message_id, address: response.to_addrs) if response
      end
    end
  end

  def reindex_children
    return unless saved_changes.keys.length > 1 # when callback is caused by touch (only updated_at is changed) and there's nothing to reindex
    ReindexChildWorker.perform_async('Review', id)
    unless @skip_reindex_children
      products.each do |product|
        ReindexChildWorker.perform_async('Product', product.id)
      end
    end
    @skip_reindex_children = false
  end

  def shopify_sync
    products.each do |product|
      product.sync_shopify_metafields
    end
  end

  def mark_as_with_incentive!
    update_attributes(with_incentive: true)
  end

  def with_incentive_text
    store.settings(:promotions).with_incentive_text
  end

  def can_auto_publish?
    store.settings(:reviews).auto_publish.to_b && rating >= store.settings(:reviews).minimum_ratings_to_publish.to_i
  end

  private

  def auto_publish
    # TODO: to_b should not be necessary. to_b || !to_b (ask for a beer when you resolve this extra challenge ;) @mizurnix )
    published! if can_auto_publish?
  end

  def set_publish_date
    return unless will_save_change_to_status?

    self.publish_date = DateTime.current if published?
  end

  def set_review_date
    self.review_date = DateTime.current if review_date.nil?
  end

  def can_search_product_groups?
    products.select{ |product| product.groups.any? }.map(&:groups).any?
  end

  def will_be_repeated?
    products = self.products.empty? ? review_reviewables.select{ |rr| rr.reviewable_type == Product.name }.map{ |rr| rr.reviewable } : self.products
    if products.any?
      customer.reviewed_products.where(id: products.pluck(:id)).where.not(reviews: { id: self.id }).any?
    end
  end

  def cannot_be_repeated
    errors.add(:product_ids, :cannot_be_repeated) if will_be_repeated?
  end

  def request_must_be_sent
    errors.add(:review_request_id, :request_must_be_sent) if !voluntary? && review_request.present? && !review_request.sent?
  end

  def cannot_be_voluntary
    errors.add(:source, :cannot_be_voluntary) if voluntary?
  end
end

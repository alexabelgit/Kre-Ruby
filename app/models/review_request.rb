class ReviewRequest < ApplicationRecord
  include Filterable

  belongs_to :order,    optional: true, touch: true
  belongs_to :customer,                 touch: true

  has_many :transaction_items
  has_many :reviews,           through: :transaction_items
  has_many :products,          through: :transaction_items, source: :reviewable, source_type: Product.name
  has_many :emails,            as: :emailable,              dependent: :destroy

  has_many :review_request_coupon_codes, dependent: :destroy

  delegate :store, :suppressed?,       to: :customer
  delegate :accepts_repeated_reviews?, to: :store
  alias_method :store_accepts_repeated_reviews?, :accepts_repeated_reviews?

  cattr_accessor :search_term
  attr_accessor  :skip_destroy_if_without_products

  validates_uniqueness_of :order_id, allow_nil: true
  validates_presence_of   :transaction_items
  validate :all_reviews_cannot_be_repeated, unless: :store_accepts_repeated_reviews?, on: :create

  after_update  :check_schedule, :destroy_if_without_products
  before_create :reindex_children, on: :create
  after_commit  :reindex_children


  enum status: [:scheduled, :pending, :incomplete, :complete, :cancelled, :on_hold] # TODO: scheduled status is not intuitive, need a better name

  searchkick word_start: [:product_names, :email],
             highlight:  [:product_names, :email],
             callbacks:  false

  scope :latest,        -> { order(created_at: :desc) }
  scope :sent,          -> { where(status: [:pending, :incomplete, :complete]) }
  scope :manual,        -> { where(order: nil) }
  scope :from_provider, -> { where.not(order: nil) }

  scope :search_import, -> {
    includes(:order, :products, customer: :store)
  }

  def search_data
    {
      email:         customer.email,
      order_id:      order&.public_id,
      store_id:      store.id,
      status:        status,
      product_names: products.map(&:name),
      created_at:    created_at
    }
  end

  def self.search_fields
    [:product_names, :email, { order_id: :exact }]
  end

  def self.sort_mapper
    {
      latest: { created_at: { order: :desc, unmapped_type: :long } }
    }
  end

  def public_id
    order.present? ? order.public_id : hashid
  end

  def from_provider?
    order.present?
  end

  def remove_mailer_jobs
    if from_provider?
      #TODO delete this part (until ###) when there will be no SendReviewRequestWorkers left with order ids
      ScheduledJobsCleaner.run(SendReviewRequestJob, order_id)
      Sidekiq::ScheduledSet.new.select{|job| job.klass == SendReviewRequestWorker.to_s && job.args == [order_id]}.each do |job|
        job.delete
      end
      ScheduledJobsCleaner.run(SendReviewRequestWorker, order_id, Order.name)
      ####
    end
    ScheduledJobsCleaner.run(SendReviewRequestWorker, id, ReviewRequest.name)
  end

  def proceed
    return cancel! unless reviewable_products.any? || transaction_items.without_products.any?

    if send_restricted?
      status = scheduled? ? :cancelled : self.status
      update_attributes(scheduled_for: nil, status: status)
      return false
    end
    uid = SecureRandom.uuid
    if scheduled? || cancelled? || on_hold?
      send_email(uid, 'review_request')
      reviews_settings = store.settings(:reviews)
      scheduled_for    = nil
      scheduled_for    = DateTime.current + reviews_settings.days_to_repeat_review_request.days + 45.seconds if reviews_settings.enable_repeat_review_request
      update_attributes(status: 'pending', scheduled_for: scheduled_for)
    elsif store.settings(:reviews).enable_repeat_review_request && (pending? || incomplete?)
      send_email(uid, 'repeat_review_request')
      update_attributes(scheduled_for: nil)
    end
  end

  def cancel!
    update_attributes(scheduled_for: nil)
    update_attributes(status: 'cancelled') if scheduled? || on_hold?
    self
  end

  def hold!
    update_attributes(scheduled_for: nil)
    update_attributes(status: :on_hold) if scheduled?
    self
  end

  def send_email(uid, email_type)
    response = FrontMailer.send(email_type, self, uid).deliver!
    emails.create(helpful_id: uid, 'smtp-id': response.message_id, address: response.to_addrs) if response
  end

  def locked?
    emails.where('created_at > ?', DateTime.current - 10.minutes).any?
  end

  def sent?
    pending? || incomplete? || complete?
  end

  def review_verifiable?
    scheduled? || pending? || incomplete?
  end

  def send_restricted?
    locked?                                                     ||
    complete?                                                   ||
    suppressed?                                                 ||
    reviewable_transaction_items.empty?                         ||
    store.settings(:admin_only).restrict_outgoing_emails.to_b   ||
    store.settings(:global).restrict_outgoing_emails.to_b
  end

  def destroy_if_without_products
    unless @skip_destroy_if_without_products
      destroy unless transaction_items.any?
    end
    @skip_destroy_if_without_products = false
  end

  def reviewable_products
    if store_accepts_repeated_reviews?
      products.unsuppressed
    else
      products.unsuppressed.where.not(id: customer.reviewed_products.pluck(:id)).uniq
    end
  end

  def reviewable_transaction_items
    if store_accepts_repeated_reviews?
      transaction_items.left_outer_joins(:product).where('products.suppressed = FALSE OR NOT transaction_items.reviewable_type = ?', Product.name)
    else
      transaction_items.left_outer_joins(:product).where("(products.suppressed = FALSE AND products.id NOT IN (#{customer.reviewed_products.any? ? customer.reviewed_products.pluck(:id).join(',') : 0})) OR NOT transaction_items.reviewable_type = ?", Product.name)
    end
  end

  def mark_as_with_incentive!
    update_attributes(with_incentive: true)
  end

  protected

  def check_schedule
    return unless saved_change_to_scheduled_for?

    remove_mailer_jobs
    SendReviewRequestWorker.perform_at(scheduled_for, id, ReviewRequest.name) if scheduled_for.present?
  end

  def all_reviews_cannot_be_repeated
    if (transaction_items.select{ |ti| ti.reviewable_type == Product.name }.map{ |ti| ti.reviewable } - customer.reviewed_products).empty?
      errors.add(:order_id, '^This customer has already reviewed all the products included in this request')
    end
  end

  def reindex_children
    return unless saved_changes.keys.length > 1 # when callback is caused by touch (only updated_at is changed) and there's nothing to reindex
    ReindexChildWorker.perform_async('ReviewRequest', id)
  end

end

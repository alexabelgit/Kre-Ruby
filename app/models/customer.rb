class Customer < ApplicationRecord
  after_commit    :reindex_children
  before_create   :reindex_children, on: :create

  belongs_to :store, touch: true

  delegate      :accepts_repeated_reviews?, :display_logo, to: :store
  alias_method  :can_repeat_reviews?, :accepts_repeated_reviews?

  has_many :orders,                  dependent: :destroy
  has_many :review_requests,         dependent: :destroy
  has_many :transaction_items,       dependent: :destroy
  has_many :reviews,                 dependent: :destroy
  has_many :questions,               dependent: :destroy
  has_many :transaction_products,    through:   :transaction_items, source: :reviewable, source_type: Product.name

  has_many :reviewed_products,          -> { distinct },     through:   :reviews,              source: :products
  has_many :reviewed_transaction_items, -> { with_reviews }, class_name: TransactionItem.name, source: :transaction_item

  has_many :imported_reviews
  has_many :imported_questions
  has_many :imported_review_requests

  has_many :suppressions

  has_many :discount_coupon_customers

  validates :name, :email, presence: true
  validates :email, 'valid_email_2/email': true

  attr_accessor :skip_reindex_children

  anonymize :name,  prefix: 'Anonymous'
  anonymize :email, prefix: 'anonymous-', unique: true, email: true

  scope     :anonymous,      -> { where(anonymized: true) }
  scope     :non_anonymous,  -> { where(anonymized: false) }

  def display_name
    name.as_display_name(store.settings(:customers).display_name_policy)
  end

  def display_initials
    name.as_initials
  end

  def first_name
    name.split[0]
  end

  def display_first_name
    display_name.split[0]
  end

  def transaction_items_except(transaction_item)
    if can_repeat_reviews?
      transaction_items.without_reviews.with_sent_requests.where.not(id: transaction_item.id).by_review_requests(transaction_item)
    else
      reviewed_product_ids = reviewed_products.pluck(:id)
      if reviewed_product_ids.empty?
        transaction_items.without_reviews.with_sent_requests.where.not(id: transaction_item.id).by_review_requests(transaction_item)
      else
        transaction_items.without_reviews
                         .with_sent_requests.where.not(id: transaction_item.id).where("transaction_items.reviewable_type \
                                                                                        IN ('#{(Review::REVIEWABLE_TYPES.values - [Product.name]).join("', '")}') \
                                                                                      OR ( NOT transaction_items.reviewable_id \
                                                                                        IN (#{reviewed_products.pluck(:id).join(',')}))")
                         .by_review_requests(transaction_item)
      end
    end
  end

  def self.generate_by_email(store, email, name = nil)
    return nil if email.blank?
    customer = store.customers.find_by(email: email)
    if customer.present?
      customer.update_attributes(name: name) if name.present?
    else
      customer = store.customers.create(email: email, name: name.presence || email.split('@').first, id_from_provider: email)
    end
    customer
  end

  def suppressed?(source = nil)
    suppressions(source).present?
  end

  def suppress(source)
    Suppression.create(store: store, email: email, source: source, customer: self) unless suppressed?(source)
  end

  def remove_from_suppression(source = nil)
    suppressions(source).destroy_all
  end

  def suppressions(source = nil)
    suppressions = Suppression.where(store: store, email: email)
    suppressions = suppressions.where(source: source) if source.present?
    suppressions
  end

  def has_discount_coupon(discount_coupon)
    discount_coupon.review_request_coupon_codes.where(review_request_id: review_requests.ids).any?
  end

  private

  def reindex_children
    return unless saved_changes.keys.length > 1 # when callback is caused by touch (only updated_at is changed) and there's nothing to reindex
    unless @skip_reindex_children
      ReindexChildWorker.perform_async('ReviewRequest', review_requests.pluck(:id)) if review_requests.any?
    end
    @skip_reindex_children = false
  end
end

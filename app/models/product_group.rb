class ProductGroup < ApplicationRecord
  after_create  :complete_onboarding_step
  after_commit  :shopify_sync, :reindex_children # TODO: doesn't reindex after delete, global issue
  before_create :reindex_children
  after_destroy :shopify_sync, :reindex_children, :destroy_product_group_products

  belongs_to :store, touch: true

  has_many :product_group_products
  has_many :products, through: :product_group_products

  has_many :reviews,   class_name: Review.name,   through: :products, source: :individual_reviews
  has_many :questions, class_name: Question.name, through: :products, source: :individual_questions

  accepts_nested_attributes_for :product_group_products

  validates :name, presence: true
  validate :products_are_unsuppressed

  def products_are_unsuppressed
    products.each do |product|
      errors.add(:product_group, 'Can not be created, because one or more products in it are suppressed') if product.suppressed
    end
  end

  scope :a24z, ->(dir = :asc) { order(name: dir) }

  def rating
    rating = reviews.published.average(:rating)
    rating.present? ? rating.round(1) : 0
  end

  private

  def destroy_product_group_products
    product_group_products.each{ |pgp| pgp.destroy }
  end

  def reindex_children
    return unless saved_changes.keys.length > 1 # when callback is caused by touch (only updated_at is changed) and there's nothing to reindex
    ReindexChildWorker.perform_async('Review', reviews.pluck(:id))     if reviews.any?
    ReindexChildWorker.perform_async('Question', questions.pluck(:id)) if questions.any?
  end

  def shopify_sync
    return unless store.shopify?
    products.find_each do |product|
      product.sync_shopify_metafields
    end
  end

  def complete_onboarding_step
    store.update_settings :onboarding, products_grouped: true
  end
end

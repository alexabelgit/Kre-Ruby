class Bundle < ApplicationRecord
  include Priceable
  include AASM

  belongs_to :store, touch: true
  has_many :bundle_items, dependent: :destroy

  has_many :plans, through: :bundle_items, source: :price_entry, source_type: 'Plan'

  has_many :addon_prices, through: :bundle_items, source: :price_entry, source_type: 'AddonPrice'
  has_many :addons, through: :addon_prices

  has_one :applied_discount, dependent: :destroy
  has_one :package_discount, through: :applied_discount

  has_one :applied_coupon, dependent: :destroy

  has_many :orders_gifts, dependent: :destroy

  has_one :subscription, foreign_key: 'bundle_id'
  has_one :initial_subscription, class_name: 'Subscription', foreign_key: 'initial_bundle_id'

  scope :not_draft, -> { where.not(state: :draft) }

  enum state: {
    draft:      0,
    processing: 1,
    active:     2,
    outdated:   3,
    disabled:   4,
    failed:     5
  }

  aasm column: :state do
    state :draft, initial: true
    state :processing # in the process of creating subscription
    state :active     # bundle is attached to subscription and will be active at the end of billing term
    state :outdated, :disabled, :failed

    after_all_events :ensure_draft_bundle_exists
    after_all_transactions :refresh_addons

    event :activate, after: :reindex_product_groups do
      transitions from: [:processing, :disabled, :outdated, :active], to: :active
    end

    event :mark_as_processing do
      transitions from: [:draft, :processing], to: :processing
    end

    event :disable, after: :reindex_product_groups do
      transitions from: :active, to: :disabled
    end

    event :outdate, after: :reindex_product_groups do
      transitions from: [:active, :processing, :disabled], to: :outdated
    end

    event :fail do
      transitions to: :failed
    end
  end

  def aasm_event_failed(event_name, old_state_name)
    errors.add(:bundle, "#{event_name} cannot transition from #{old_state_name}")
  end

  def refresh_addons
    return unless addons_enabled?
    EnabledAddon.refresh
  end

  def platform
    store.ecommerce_platform
  end

  def contains?(addon)
    return false unless addons_enabled?
    addon_prices.where(addon: addon).present?
  end

  def plan_name
    plan_record&.name
  end

  def plan_description
    plan_record&.description
  end

  def plan_orders_limit
    plan_record&.orders_limit
  end

  def plan_price
    plan_record&.price_in_cents
  end

  def plan_price_in_dollars
    in_dollars(plan_price)
  end

  def plan_extended_orders_limit
    plan_record&.extended_orders_limit
  end

  def plan_extension_price
    plan_record&.extension_price_in_cents
  end

  def plan_extensible?
    plan_extension_price.present? && plan_extended_orders_limit.present?
  end

  def plan_extension_price_in_dollars
    in_dollars(plan_extension_price)
  end

  def total_price
    Rails.cache.fetch [self, 'total_price'] do
      return 0 unless plan_price
      addons_price + plan_price
    end
  end

  def raw_price
    Rails.cache.fetch [self, 'raw_price'] do
      plan_price + raw_addons_price
    end
  end

  def raw_addons_price
    return 0 unless addons_enabled?
    Rails.cache.fetch [self, 'raw_addons_price'] do
      addon_prices.sum(&:price_in_cents)
    end
  end

  def addons_price
    Rails.cache.fetch [self, 'addons_price'] do
      raw_addons_price - discount_amount
    end
  end

  def discount_amount
    package_discount = PackageDiscount.bundle_discount self
    return 0 if package_discount.blank?

    raw_addons_price * package_discount.discount_percents / 100.0
  end

  def dollars_price
    in_dollars(total_price)
  end

  def total_price_in_dollars
    in_dollars(total_price)
  end

  def enabled_addons
    addon_prices.includes(:addon)
  end

  def has_addons?
    return false unless addons_enabled?
    addon_prices.any?
  end

  def has_subscription?
    subscription && !subscription.initialized?
  end

  def summary
    addons_count  = addon_prices.count
    addons_word   = 'add-on'.pluralize(addons_count)
    addons_suffix = addons_count.nonzero? ? " + #{addons_count} #{addons_word}" : ''

    plan_name + addons_suffix
  end

  # fetch latest bundle plan, we expect it always have only one though
  def plan_record
    plans.order('bundle_items.id DESC').first
  end

  def addons_enabled?
    store.addons_feature_enabled?
  end

  def gifted_orders_in_period(time_interval)
    orders_gifts.where(applied_at: time_interval).sum(:amount) || 0
  end

  private

  def ensure_draft_bundle_exists
    Bundles::CreateBundle.run(store: store) if store.draft_bundle.blank?
  end

  def reindex_product_groups
    return unless contains?(Addon.product_groups)

    StoreReindexer.new(store).reindex_product_groups
  end
end

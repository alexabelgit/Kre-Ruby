class Subscription < ApplicationRecord
  belongs_to :bundle, touch: true
  belongs_to :initial_bundle, touch: true, class_name: 'Bundle'
  belongs_to :chargebee_customer

  has_many :payments, dependent: :destroy

  include AASM

  enum state: {
    initialized:  0,
    pending:      1,
    processing:   2,
    active:       3,
    failed:       4,
    suspended:    5,
    cancelled:    6, # user cancelled renewal but has some time left till expiration
    archived:     7, # renewal cancelled and subscription already expired
    declined:     8, # user declined subscription during processing stage
    reactivating: 9, # subscription was cancelled but we're trying to reactivate it
    non_renewing: 10,
    withheld:     11 # admin can manually withhold gifted subscription that if over quota
  }

  aasm column: :state do
    state :initialized, initial: true
    state :pending, :processing, :reactivating # pending states
    state :active, :non_renewing # active states
    state :failed, :suspended, :cancelled, :archived, :withheld # disabled states

    event :activate do
      transitions from: [:active, :pending, :processing, :non_renewing,
                         :suspended, :cancelled, :reactivating, :withheld], to: :active
    end

    event :await_acceptance do
      transitions from: [:initialized, :pending], to: :pending
    end

    event :await_reactivation do
      transitions from: [:cancelled, :non_renewing, :reactivating], to: :reactivating
    end

    event :suspend do
      transitions from: :active, to: :suspended
    end

    event :cancel, before: :set_expired_at do
      transitions from: [:active, :non_renewing, :suspended], to: :cancelled
    end

    event :stop_renewal do
      transitions from: [:non_renewing, :active], to: :non_renewing
    end

    event :withhold do
      transitions from: [:active], to: :withheld
    end

    event :release_hold do
      transitions from: [:withheld], to: :active
    end

    event :archive do
      transitions from: [:cancelled], to: :archived
    end

    event :fail do
      transitions to: :failed
    end
  end

  delegate :platform,
           :store,
           :total_price_in_dollars,
           to: :bundle

  delegate :name, :description, :orders_limit, :price_in_dollars,
           :extensible?, :extended_orders_limit, :extension_price_in_dollars,
           to: :active_plan,
           prefix: :plan

  delegate :plan_price, :affiliate?, :overages_limit,
           to: :active_plan

  # we don't archive subscriptions with debt
  scope :to_be_archived, -> { where(state: :cancelled)
                              .where('total_due = 0')
                              .where('expired_at < ?', 1.day.ago) }

  scope :live, -> { where(state: [:active, :non_renewing])}

  scope :dunning, -> { live.where('total_due > 0') }
  scope :recently_cancelled, -> { order('cancelled_on DESC') }

  scope :at_the_end_of_billing_cycle, -> { where(next_billing_at: DateTime.current..DateTime.current + 3.hours) }

  def chargebee?
    processing_platform == 'chargebee'
  end

  def changed_during_billing_cycle?
    initial_bundle.present?
  end

  def live?
    active? || terminating?
  end

  def terminating?
    non_renewing? && expired_at.present? && expired_at > DateTime.current
  end

  def chargeable_automatically?
    id_from_provider.nil?
  end

  def gifted?
    (active? || withheld?) && id_from_provider.nil?
  end

  def real?
    !gifted?
  end

  def active_plan
    @active_plan ||= ActivePlan.new(self)
  end

  def user
    bundle&.store&.user
  end

  def has_debt?
    total_due.positive?
  end

  def current_billing_cycle
    next_billing_at - 1.month .. next_billing_at
  end

  def payments_within_billing_cycle(payment_type:)
    payments.where(payment_type: payment_type).where(payment_made_at: current_billing_cycle)
  end



  def products_limit_in_billing_cycle
    Rails.cache.fetch [self, 'products_limit_in_billing_cycle'] do
      return nil unless active_plan.max_products_limit

      active_plan.max_products_limit + gifted_products
    end
  end

  def gifted_products
    return 0 if gifted_products_amount.blank?
    return 0 if gifted_products_valid_till.present? && gifted_products_valid_till < next_billing_at

    gifted_products_amount
  end

  def orders_limit_in_billing_cycle
    limit = active_plan.orders_limit + bundle.gifted_orders_in_period(current_billing_cycle)
    if initial_bundle
      limit += initial_bundle.gifted_orders_in_period(current_billing_cycle)
    end
    limit
  end

  def dunning?
    live? && has_debt?
  end

  def payment_method
    chargebee_customer&.latest_payment_method
  end

  def set_expired_at
    self.expired_at = cancelled_on unless expired_at
  end

  private

  def overage_charges_launch_date
    Rails.configuration.billing.overage_charges_launch_date
  end

end

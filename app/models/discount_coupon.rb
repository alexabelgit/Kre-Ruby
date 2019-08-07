class DiscountCoupon < ApplicationRecord
  belongs_to :store

  has_many :promotion_discount_coupons, dependent: :destroy, inverse_of: :discount_coupon
  has_many :promotions,                 through:   :promotion_discount_coupons

  has_many :coupon_codes,                dependent: :destroy
  has_many :review_request_coupon_codes, through:   :coupon_codes

  scope :latest,             -> { order(created_at: :desc) }
  scope :a24z,               -> (dir = :asc) { order(name: dir) }
  scope :active_dates,       -> { where('valid_from <= ?', DateTime.current.beginning_of_day).where('valid_until IS NULL OR valid_until >= ?', DateTime.current.end_of_day) }
  scope :active,             -> { visible.active_dates.where('discount_coupons.limit IS NULL OR discount_coupons.limit > discount_coupons.issue_count') }
  scope :active_or_archived, -> { archived.or(active) }

  enum status: {
    visible: 0,
    archived: 1
  }

  enum discount_sequence: {
    symbol_after: 0,
    symbol_before: 1
  }

  enum code_type: {
    reusable: 0,
    unique: 1
  }

  enum send_per: {
    customer: 0,
    order: 1
  }, _prefix: true

  SEND_PER = {
    customer: 'First Order Only',
    order:    'Every order'
  }

  STATUS_TEXT = {
    visible:  'restored',
    archived: 'archived'
  }

  STATUS_FLASH_TYPE = {
    visible:  :success,
    archived: :info
  }

  validates                 :valid_until, not_in_past: true
  validate                  :must_start_before_end
  validates_numericality_of :limit, allow_nil: true, greater_than_or_equal_to: 1
  validates_numericality_of :issue_count, greater_than_or_equal_to: 0
  validates_presence_of     :coupon_codes
  validates_presence_of     :name
  validates_uniqueness_of   :name

  # Before validation set starts to beginning of day and ends to end of day
  before_validation do
    self.valid_from   = valid_from.beginning_of_day   if valid_from.present? && valid_from_changed?
    self.valid_until  = valid_until.end_of_day        if valid_until.present? && valid_until_changed?
  end

  def status_flash_type
    STATUS_FLASH_TYPE[status.to_sym]
  end

  def status_text
    STATUS_TEXT[status.to_sym]
  end

  def code
    reusable? ? (current_coupon_code.present? ? current_coupon_code.code : '') : ''
  end

  def make_code_current(coupon_code)
    coupon_codes.where.not(id: coupon_code.id).each(&:unmake_current)
    coupon_code.make_current
  end

  def coupon_code
    unique? ? coupon_codes.free.oldest.first : current_coupon_code
  end

  def current_coupon_code
    current_codes = coupon_codes.current
    current_codes.any? ? current_codes.last : coupon_codes.first
  end

  def discount_text
    if symbol_before?
      "#{discount_type}#{discount_amount}"
    else
      "#{discount_amount}#{discount_type}"
    end
  end

  def in_use?
    visible? && promotions.any?
  end

  def source
    id_from_provider.present? ? 'eCommerce' : 'Manual'
  end

  def active?
    visible? && valid_from <= DateTime.current.beginning_of_day && (valid_until.nil? || valid_until >= DateTime.current.end_of_day) && (limit.nil? || issue_count < limit) && (reusable? || coupon_codes.free.any?)
  end

  def active_for_review_request?(review_request)
    valid_until.nil? || (review_request.from_provider? && review_request.order.order_date <= valid_until.end_of_day) || review_request.created_at <= valid_until.end_of_day
  end

  def valid_from_text
    valid_from.strftime(DateFormat.string_format(store.settings(:global).date_format))
  end

  def valid_until_text
    valid_until&.strftime(DateFormat.string_format(store.settings(:global).date_format)) || 'infinity'
  end

  private

  def must_start_before_end
    if valid_from && valid_until
      errors.add(:valid_until, '^End date must be greater than start date') if valid_from > valid_until
    end
  end
end

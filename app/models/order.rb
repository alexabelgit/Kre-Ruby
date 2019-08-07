class Order < ApplicationRecord
  STATUSES =
    {
      placed:    'order is placed',
      paid:      'payment is complete',
      shipped:   'order is shipped',
      delivered: 'order is delivered'
    }.freeze

  belongs_to :customer, touch: true

  has_one  :review_request, dependent: :destroy

  has_many :transaction_items
  has_many :reviews,           through: :transaction_items
  has_many :products,          through: :transaction_items, source: :reviewable, source_type: Product.name

  delegate :store, to: :customer

  validates_presence_of :order_date
  validate              :is_not_too_old, on: :create

  extend DisplayMoney
  money_methods :total, :item_total

  def public_id
    order_number || hashid
  end

  protected

  def is_not_too_old
     errors.add(:order_date, 'is too old') if DateTime.current > (order_date + 1.year)
  end
end

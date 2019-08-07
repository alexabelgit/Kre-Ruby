class PaymentMethod < ApplicationRecord
  belongs_to :chargebee_customer
  has_many :subscriptions

end

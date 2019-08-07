class ChargebeeCustomer < ApplicationRecord
  belongs_to :store
  has_many :subscriptions
  has_many :payment_methods

  def latest_payment_method
    payment_methods.last
  end
end

class Email < ApplicationRecord

  belongs_to :emailable,    polymorphic: true
  has_many   :email_events, dependent:   :destroy
  delegate   :store,        to:          :emailable

  validates_uniqueness_of :helpful_id

end

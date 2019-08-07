class EmailEvent < ApplicationRecord

  belongs_to :email
  enum source: [:sendgrid, :hc]

end
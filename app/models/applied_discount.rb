class AppliedDiscount < ApplicationRecord
  belongs_to :package_discount
  belongs_to :bundle
end

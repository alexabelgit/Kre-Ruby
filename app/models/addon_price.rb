class AddonPrice < ApplicationRecord
  include Priceable
  include Proratable
  include Deprecatable
  include WithEcommercePlatform

  belongs_to :addon
  has_many :bundle_items, as: :price_entry

  delegate :name, to: :addon
end

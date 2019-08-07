class BundleItem < ApplicationRecord
  belongs_to :price_entry, polymorphic: true
  belongs_to :bundle, touch: true
end

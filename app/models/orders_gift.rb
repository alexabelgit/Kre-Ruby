class OrdersGift < ApplicationRecord
  belongs_to :bundle, touch: true
end


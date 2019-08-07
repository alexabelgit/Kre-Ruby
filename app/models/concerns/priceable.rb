module Priceable
  extend ActiveSupport::Concern

  def price_in_dollars
    in_dollars price_in_cents
  end

  def in_dollars(price)
    return price unless price.is_a?(Numeric)
    (price / 100.0).round(2)
  end

  def in_dollars_as_currency(price, view = ActionView::Base.new)
    view.number_to_currency in_dollars(price)
  end
end

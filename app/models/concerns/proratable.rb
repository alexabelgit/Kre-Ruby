module Proratable
  extend ActiveSupport::Concern

  def prorated_price(days)
    price_in_cents * days/days_in_month
  end

  private

  def days_in_month
    DateTime.current.end_of_month.day
  end
end

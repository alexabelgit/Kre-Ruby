FactoryBot.define do
  factory(:order) do
    sequence(:id_from_provider) { |n| "1#{n}" }
    order_date { DateTime.current }
    customer
  end
end

FactoryBot.define do
  factory :addon_price do
    price_in_cents { 99 }
    addon
    ecommerce_platform
  end
end

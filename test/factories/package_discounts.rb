FactoryBot.define do
  factory :package_discount do
    discount_percents { 10 }
    addons_count { 2 }
    ecommerce_platform
  end
end

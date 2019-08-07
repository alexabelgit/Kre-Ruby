FactoryBot.define do
  factory :plan do
    name { 'Essential' }
    slug { :essential }
    ecommerce_platform
    price_in_cents { 499 }

    trait :deprecated do
      deprecated_at { 2.days.ago }
    end
  end
end

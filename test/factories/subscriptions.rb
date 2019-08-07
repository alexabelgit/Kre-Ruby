FactoryBot.define do
  factory :subscription do
    last_payment_at { "2017-12-22 00:37:00" }
    expired_at { "2017-12-22 00:37:00" }

    association :bundle, :active
    sequence(:id_from_provider) { |n| "id_from_provider_#{n}" }

    trait :pending do
      state { :pending }
    end

    trait :active do
      state { :active }
    end

    trait :gifted do
      id_from_provider { nil }
    end
  end
end

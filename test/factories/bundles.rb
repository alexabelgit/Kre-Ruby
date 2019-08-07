FactoryBot.define do
  factory :bundle do
    store

    trait :active do
      state { 'active' }
    end

    trait :disabled do
      state { 'disabled' }
    end

    trait :processing do
      state { 'processing' }
    end
  end
end

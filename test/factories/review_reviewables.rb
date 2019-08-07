FactoryBot.define do
  factory :review_reviewable do
    review

    trait(:with_product) do
      association :reviewable, factory: :product
    end

    trait(:with_business) do
      association :reviewable, factory: :store
    end
  end
end

FactoryBot.define do
  factory :comment do
    body { "good product" }
    user
    display_name { "Nice!" }

    trait(:with_product) do
      association :commentable, factory: :product
    end

    trait(:with_question) do
      association :commentable, factory: :question
    end
  end
end

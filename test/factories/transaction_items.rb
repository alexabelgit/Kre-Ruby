FactoryBot.define do
  factory(:transaction_item) do
    customer
    order

    trait(:with_product) do
      association :reviewable, factory: :product
    end

    trait(:with_business) do
      association :reviewable, factory: :store
    end
  end
end

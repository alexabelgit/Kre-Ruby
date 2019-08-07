FactoryBot.define do
  factory :addon do
    name { "Product groups" }
    slug { :product_groups }
    description { "Product groups allow to group product in groups" }
    state { 1 }
  end
end

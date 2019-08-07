FactoryBot.define do
  factory :store do
    access_token { 'secret_v5P9K2cimgEF6PmFKLG1tB57vGgHBiuA' }
    sequence(:id_from_provider) { |n| "10276356#{n}" }
    legal_name { "Whisky Grape Company" }
    name { 'Whisky & Grape' }
    url { 'https://whiskyandgrape.ecwid.com/' }
    trial_ends_at { 30.days.from_now }

    ecommerce_platform
    user

    trait :installed do
      access_token { 'some_token' }
    end

    factory :shopify_store do
      name { 'Store With Dot' }
      url { "https://store-with-dot.myshopify.com" }
      domain { 'store-with-dot.myshopify.com' }
    end
  end
end

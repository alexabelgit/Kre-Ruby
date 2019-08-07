FactoryBot.define do
  factory :social_account do
    user { nil }
    provider { "MyString" }
    uid { "MyString" }
    access_token { "MyString" }
  end
end

FactoryBot.define do
  factory :coupon do
    name { "MyString" }
    description { "MyString" }
    code { "MyString" }
    discount_type { 1 }
    discount_value { 1.5 }
    state { 1 }
    expired_at { "2017-12-22 00:31:10" }
    platform { 1 }
    available_usages { 1 }
  end
end

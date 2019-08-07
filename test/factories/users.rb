FactoryBot.define do
  factory(:user) do
    sequence(:email) { |n| "test_#{n}@example.com" }
    first_name { 'Test' }
    last_name { 'User' }
    password { 'test_password' }
    password_confirmation { 'test_password' }
    confirmed_at { Time.zone.now }

    factory :admin do
      role { :admin }
    end
  end
end

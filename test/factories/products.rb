FactoryBot.define do
  factory(:product) do
    sequence(:id_from_provider) { |n| "123456#{n}" }
    name { 'Extraordinarily good tea from Chinese fields' }

    store
  end
end

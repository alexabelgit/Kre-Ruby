FactoryBot.define do
  factory(:customer) do
    email { 'mezurnishvili.giorgi@gmail.com' }
    id_from_provider { 'mezurnishvili.giorgi@gmail.com' }
    name { 'Givi Dochviri' }

    store
  end
end

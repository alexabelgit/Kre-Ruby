FactoryBot.define do
  factory(:review) do
    status { 'pending' }
    feedback { "Nice product" }
    rating { 5 }

    customer
    transaction_item
  end
end

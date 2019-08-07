return if ENV['APP_ENV'] == 'production'

Dir[File.join(Rails.root, 'db', 'seeds/*.rb')].each do |seed|
  require seed
end

SeedBilling.new.run

rand = SecureRandom.base58

# Create user
user = User.find_by email: 'admin@example.com'

unless user
  user = User.new(
    first_name:            'Admin',
    last_name:             'Istrator',
    email:                 'admin@example.com',
    role:                  'admin',
    password:              'asdfqwer',
    password_confirmation: 'asdfqwer'
  )
  user.skip_confirmation!
  user.save!
end

# Create store
store = Store.find_by user: user, name: "Whisky & Grape"

unless store
  params = {
    url:              ENV['SEEDED_STORE_URL'],
    name:             "Whisky & Grape",
    legal_name:       "Whiskyandgrape Limited",
    access_token:     SecureRandom.base58,
    provider:         'custom',
    id_from_provider: SecureRandom.base58,
    user:             user
  }
  outcome = Stores::CreateStore.run params
  if outcome.valid?
    store = outcome.result
  else
    puts outcome.errors.messages
    return
  end
end

# Prepare method to create products
def create_product(store:, name:, id_from_provider:, category:, url:)
  product = Product.find_by store: store, name: name

  return product if product

  Product.create store: store, name: name, id_from_provider: id_from_provider, category: category, url: url
end

# Create first product
first_product =
  create_product store:            store,
                 name:             'Aberfeldy 12 Year Old',
                 id_from_provider: '0000010',
                 category:         'Single Malt Scotch',
                 url:              "#{ENV['SEEDED_STORE_URL']}/products/aberfeldy-12-year-old.html"

# Create second product
second_product =
  create_product store:            store,
                 name:             'Balblair 1999',
                 id_from_provider: '0000020',
                 category:         'Single Malt Scotch',
                 url:              "#{ENV['SEEDED_STORE_URL']}/products/balblair-1999.html"

# Create third product
third_product =
  create_product store:            store,
                 name:             'Fettercairn',
                 id_from_provider: '0000060',
                 category:         'Blended Scotch',
                 url:              "#{ENV['SEEDED_STORE_URL']}/products/fettercairn.html"

# Create customer
customer =
  store.customers.create email:            'merry@example.com',
                         name:             'Merry Custo',
                         id_from_provider: rand

# Create order
order =
  customer.orders.create id_from_provider: rand,
                         order_number:     rand,
                         order_date:       DateTime.current

# Create transaction_items objects for order
tis = [first_product, second_product, third_product, store].map do |reviewable|
  TransactionItem.create order: order, reviewable: reviewable, customer: order.customer
end

# Create review request
review_request = ReviewRequest.new status: 1, order: order, customer: order.customer

order.transaction_items.each do |transaction_item|
  review_request.transaction_items << transaction_item
end

review_request.save

first_ti, second_ti, third_ti, fourth_ti = tis

# Create reviews
::Reviews::CreateReview.run transaction_item: first_ti,
                           status:           :published,
                           rating:           5,
                           feedback:         'Superb quality and fast delivery. Thanks!',
                           review_date:      DateTime.current

::Reviews::CreateReview.run transaction_item: second_ti,
                           status:           :published,
                           rating:           4,
                           feedback:         'Really nice. A bit slow delivery though, hence 4 stars. Product itself is the top quality',
                           review_date:      DateTime.current

::Reviews::CreateReview.run transaction_item: third_ti,
                           status:           :published,
                           rating:           3,
                           feedback:         'Expected it to be better. It is an OKAY experience, not more, not less',
                           review_date:      DateTime.current

::Reviews::CreateReview.run transaction_item: fourth_ti,
                           status:           :published,
                           rating:           5,
                           feedback:         'The business is Great!',
                           review_date:      DateTime.current

# Create question
Question.create product:  third_product,
                status:   1,
                body:     'Does it come in different packaging?',
                customer: customer

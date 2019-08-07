class GuestCustomer
  attr_reader :name, :email

  def initialize(name:, email:)
    @name = name
    @email = email
  end

  def self.from_customer_header(customer_header)
    json = JSON.parse(customer_header, symbolize_names: true)

    name = CGI::unescape(json[:name])
    email = CGI::unescape(json[:email])
    new(name: name, email: email)
  end

  def valid?
    name.present? && email.present?
  end

  def cache_key
    ['guest-customer',name,email].join('-')
  end
end
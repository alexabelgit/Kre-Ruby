require 'money'
require 'money/bank/open_exchange_rates_bank'

money_bank = Money::Bank::OpenExchangeRatesBank.new
money_bank.app_id = ENV['OPEN_EXCHANGE_BANK_ACCESS_KEY']
money_bank.ttl_in_seconds = 1.day.to_i
money_bank.source = ENV['DEFAULT_CURRENCY']

if Rails.env.test?
  money_bank.cache = "tmp/exchange_rates.json"
else
  money_bank.cache = Proc.new do |data|
    key = 'money:openexchangerates:bank'.freeze
    Redis.current.with do |conn|
      if data
        conn.set(key, data)
      else
        conn.get(key)
      end
    end
  end
end

# Update rates first time from initializer if conversion rates not saved in memory
unless Money.default_bank.get_rate('USD', 'CAD')
  money_bank.update_rates
end

Money.default_currency = Money::Currency.new(ENV['DEFAULT_CURRENCY'])
Money.default_bank = money_bank

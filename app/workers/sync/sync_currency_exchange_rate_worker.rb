require 'sidekiq-scheduler'

class SyncCurrencyExchangeRateWorker
  include Sidekiq::Worker
  sidekiq_options queue: :low

  ### SIDEKIQED

  def perform
    Money.default_bank.update_rates
  end
end

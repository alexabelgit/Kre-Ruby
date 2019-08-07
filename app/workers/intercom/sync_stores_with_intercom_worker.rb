require 'sidekiq-scheduler'

module Intercom
  class SyncStoresWithIntercomWorker
    include Sidekiq::Worker
    sidekiq_options queue: :low, retry: 3

    def perform
      Store.recently_updated.find_each do |store|
        UpdateIntercomCompanyWorker.perform_async store.id
      end
    end
  end
end

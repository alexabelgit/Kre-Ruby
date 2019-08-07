require 'sidekiq-scheduler'

module Intercom
  class SyncUsersWithIntercomWorker
    include Sidekiq::Worker

    sidekiq_options queue: :low, retry: 3

    def perform
      ::User.recently_updated.find_each do |user|
        UpdateIntercomUserWorker.perform_async user.id
      end
    end
  end
end
module System
  class ExpiredDownloadsCleanupWorker
    include Sidekiq::Worker
    sidekiq_options queue: :low

    def perform
      Download.expired.destroy_all
    end
  end
end
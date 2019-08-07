require 'sidekiq-scheduler'

module System

    class ReindexWorker
        include Sidekiq::Worker

        def perform
            Searchkick::ProcessQueueJob.perform_later(class_name: 'Review')
            Searchkick::ProcessQueueJob.perform_later(class_name: 'ReviewRequest')
            Searchkick::ProcessQueueJob.perform_later(class_name: 'Question')
            Searchkick::ProcessQueueJob.perform_later(class_name: 'Product')
            Searchkick::ProcessQueueJob.perform_later(class_name: 'ReviewRequestCouponCode')
        end
    end
end

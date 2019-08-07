class RetryFailedReindexJob < ApplicationJob
  queue_as :low

  def perform
    puts "#{DateTime.current.to_s} [INFO] Retrying failed searchkick reindex jobs"
    for i in 0..Resque::Failure.count-1
      break if i >= Resque::Failure.count
      if Resque::Failure.all(i, 1)['queue'] == 'searchkick'
        Resque::Failure.requeue(i)
        Resque::Failure.remove(i)
        redo
      end
    end
  end

end

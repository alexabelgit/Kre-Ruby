module Sidekiq
  module Worker
    module ClassMethods
      def perform_uniq_in(interval, *args)
        is_unique = Sidekiq::ScheduledSet.new.none? { |job| job.klass == self.to_s && job.args == args }
        perform_in(interval, *args) if is_unique
      end
    end
  end
end

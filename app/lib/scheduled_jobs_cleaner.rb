class ScheduledJobsCleaner

  def self.run(klass, *args)
    if klass.name.include?('Job') && klass.superclass == ApplicationJob
      Resque.remove_delayed_selection { |params| params[0]['job_class'] == klass.to_s && params[0]['arguments'][0..args.length] == args }
    elsif klass.name.include?('Worker')
      Sidekiq::ScheduledSet.new.select{|job| job.klass == klass.to_s && job.args[0..args.length] == args}.each do |job|
        job.delete
      end
    end
  end

end

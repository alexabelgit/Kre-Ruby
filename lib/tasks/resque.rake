require 'resque/tasks'
require 'resque/scheduler/tasks'

namespace :resque do
  task :setup do
    require 'resque'
    require 'resque-scheduler'
  end
  task :setup_schedule => :setup do
    require 'resque-scheduler'
  end
  task :scheduler => :setup_schedule
end

Resque.after_fork = Proc.new { ActiveRecord::Base.establish_connection }

desc 'Alias for resque:work (To run workers on Heroku)'
task 'jobs:work' => 'resque:work'

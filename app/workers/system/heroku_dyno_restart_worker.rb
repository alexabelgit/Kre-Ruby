require 'sidekiq-scheduler'

class HerokuDynoRestartWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default

  DYNO_LIFETIME = ENV['DYNO_LIFETIME_HOURS']&.to_i&.hours || 24.hours

  def perform
    return unless restart_dynos?

    require 'platform-api'
    heroku = PlatformAPI.connect_oauth heroku_token
    web_dynos = heroku.dyno.list(heroku_name).select{ |x| x['type'] == 'web' }
    web_dynos.each do |dyno|
      restart_dyno heroku, dyno
    end
  end

  private

  def restart_dynos?
    dyno_lifetime_enabled? && staging_or_production? && heroku_name.present?
  end

  def heroku_token
    ENV['PLATFORM_API_TOKEN']
  end

  def heroku_name
    ENV['HEROKU_NAME']
  end

  def dyno_lifetime_enabled?
    ENV['DYNO_LIFETIME_HOURS'].present?
  end

  def staging_or_production?
    %w(development staging production).include? ENV['APP_ENV']
  end

  def restart_dyno(heroku, dyno)
    need_to_restart_dyno = DateTime.current - DYNO_LIFETIME > dyno['created_at']
    return unless need_to_restart_dyno

    heroku.dyno.restart(heroku_name, dyno['id'])
  end
end

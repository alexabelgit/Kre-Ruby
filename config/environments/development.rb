Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  config.active_job.queue_adapter = :inline

  # Enable/disable caching. By default caching is disabled.
  if Rails.root.join('tmp/caching-dev.txt').exist?
    config.action_controller.perform_caching = true

    config.cache_store = :redis_cache_store, { url: ENV['REDIS_URL'] }
    config.public_file_server.headers =
      {
        'Cache-Control' => 'public, max-age=172800'
      }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  config.active_record.verbose_query_logs = true

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = ENV['DEBUG_LOCAL_ASSETS'].to_b

  config.assets.digest = false # This is here to make pages render faster, based on a comment from this post: https://stackoverflow.com/questions/16744279/rails-development-server-is-slow-and-takes-a-long-time-to-load-a-simple-page

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Raises error for missing translations
  config.action_view.raise_on_missing_translations = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker

  config.force_ssl = true if config.urls_config.app_protocol == 'https'

  config.action_cable.url = "ws://#{config.urls_config.app_host}:#{config.urls_config.app_port}/cable"

  config.action_controller.default_url_options = config.urls_config.url_options

  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.perform_caching = false
  config.action_mailer.asset_host =  config.urls_config.asset_host
  config.action_mailer.default_url_options = { host: config.urls_config.app_host, port: config.urls_config.app_port }
  config.action_mailer.delivery_method = :letter_opener if ENV['PREVIEW_EMAILS']

  config.after_initialize do
    Bullet.enable = true
    Bullet.bullet_logger = false
    Bullet.console = false
    Bullet.add_footer = false
    Bullet.alert = false
  end

  config.heroku_review_app = false
  config.user_as_admin_by_default = false
  #
  # # Send mails via test Sendgrid account on Development
  # config.action_mailer.smtp_settings = {
  #   :address   => "smtp.sendgrid.net",
  #   :port      => 587, # ports 587 and 2525 are also supported with STARTTLS
  #   :enable_starttls_auto => true, # detects and uses STARTTLS
  #   :user_name => "apikey",
  #   :password  => ENV["SENDGRID_API_KEY"], # SMTP password is any valid API key, when user_name is "apikey".
  #   :authentication => 'plain',
  #   :domain => 'helpfulcrowd.com', # your domain to identify your server when connecting
  # }
end

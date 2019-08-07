require_relative 'boot'
require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module HelpfulCrowd
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    config.autoload_paths += Dir[File.join(Rails.root, 'lib', 'helpers', '*.rb')].each { |l| require l }
    config.autoload_paths += Dir[File.join(Rails.root, 'lib', 'lemonstand_api', 'lib', '*.rb')].each { |l| require l }
    config.autoload_paths += Dir[File.join(Rails.root, 'app', 'lib', 'sidekiq', 'worker', '*.rb')].each { |l| require l }

    require "#{config.root}/app/lib/urls_config"
    UrlsConfig.init(Rails.configuration)

    %w(commands presenters queries workers).each do |directory|
      config.eager_load_paths += Dir.glob("#{Rails.root}/app/#{directory}/**/**/")
    end

    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins  [ENV.fetch('ASSET_HOST', '*'), Rails.configuration.urls_config.fallback_asset_host]
        resource '/assets/*', headers: :any, methods: :get
      end
      %w(/f/* /res/*).each do |prefix|
        allow do
          origins  { |source, _| source }
          resource prefix, headers: ['HC_GUEST_CUSTOMER', 'HC_LOCALE'], methods: :any, credentials: true
        end
      end
    end

    config.active_record.schema_format = :sql

    config.middleware.insert_after ActionDispatch::Static, Rack::Deflater

    config.generators do |g|
      g.fixture_replacement :factory_bot
    end

    Groupdate.time_zone = 'UTC'

    # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
    # the I18n.default_locale when a translation cannot be found).
    config.i18n.fallbacks = [I18n.default_locale]

    config.middleware.insert_before(Rack::Runtime, Rack::Rewrite) do
      r301 '/users/sign_in',        '/sign-in'
      r301 '/users/sign_up',        '/sign-up'
      r301 '/users/cannot_sign_in', '/cannot-sign-in'

      # TODO: This should be temporary. Need to find all usages of /review_book
      #       and ask users to change it to /review_journal
      r301  %r{\/(\w+)\/widgets\/review_book.js\z}, '/f/$1/widgets/review_journal.js', not: %r{\/f\/}

      # These redirects are due to new nesting of front urls, we can remove it if those urls ever expire
      r301  %r{\/(\w+)\/widgets\/(\w+).js\z}, '/f/$1/widgets/$2.js', not: %r{\/f\/|\/cp\/}
      r301  %r{\/(\w+)\/requests\/(\w+)(.*)}, '/f/$1/requests/$2$3', not: %r{\/f\/|\/cp\/}

      r301  %r{\/(\w+)\/products\/(\w+)\/reviews\/(\w+)\z},        '/f/$1/products/$2/reviews/$3',              not: %r{\/f\/|\/cp\/}
      r301  %r{\/(\w+)\/products\/(\w+)\/reviews\/(\w+)(\?.*)},    '/f/$1/products/$2/reviews/$3$4',            not: %r{\/f\/|\/cp\/}

      r301  %r{\/(\w+)\/products\/(\w+)\/questions\/(\w+)\z},      '/f/$1/products/$2/questions/$3',            not: %r{\/f\/|\/cp\/}
      r301  %r{\/(\w+)\/products\/(\w+)\/questions\/(\w+)(\?.*)},  '/f/$1/products/$2/questions/$3$4',          not: %r{\/f\/|\/cp\/}

      r301  %r{\/(\w+)\/suppressions\/manage_subscriptions(\?.*)}, '/f/$1/suppressions/manage_subscriptions$2', not: %r{\/f\/|\/cp\/}
    end
  end
end

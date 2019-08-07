source 'https://rubygems.org'
ruby '2.6.1'

gem 'rails', '= 5.2.2'
gem 'rails-i18n', '~> 5.1'

gem 'dotenv-rails', require: 'dotenv/rails-now', groups: [:development, :test]
gem 'pg'

gem 'hiredis'
gem 'redis', '~> 4.0.2'

gem 'puma', '~> 3.0'
gem 'sass-rails', '~> 5.0', '>= 5.0.6'
gem 'sassc-rails'

gem 'sprockets', '3.7.1'
gem 'uglifier', '>= 1.3.0'
gem 'coffee-rails', '~> 4.2'
gem 'jquery-rails'
gem 'turbolinks', '~> 5'
gem 'jbuilder', '~> 2.5'
gem 'slim-rails'

gem 'bootsnap', '>= 1.1.0', require: false

gem 'mini_racer', '~> 0.2.6'

gem 'normalize-rails'
gem 'wetsy', git: 'https://github.com/mizurnix/wetsy.git'
gem 'autoprefixer-rails'

gem 'carrierwave', '~> 1.2'
gem 'cloudinary'

gem 'fastimage'

gem 'ledermann-rails-settings'
gem 'inquisitor', git: 'https://github.com/nkadze/inquisitor.git'

gem 'devise'
gem 'pretender'

gem 'omniauth-facebook'
gem 'omniauth-twitter'
gem 'omniauth-shopify-oauth2', '= 1.2.1' # probably good idea to postpone upgrade to 2.x versions due to issues like https://github.com/Shopify/omniauth-shopify-oauth2/issues/72

gem 'koala'
gem 'twitter', '~> 6.2'
gem 'twitter-text'

gem 'aws-sdk', '~> 3'

gem 'hashid-rails', git: 'https://github.com/raeno/hashid-rails'
gem 'wannabe_bool'

gem 'meta-tags'
gem 'active_link_to'
gem 'will_paginate', '~> 3.1.0'
gem 'country_select'
gem 'valid_email2'
gem 'validate_url'

# Using rouge for syntax highlighting
gem 'rouge', '~> 3.1'

gem 'chartkick'
gem 'groupdate'
gem 'sendgrid-ruby'

gem 'activeresource',     git: 'https://github.com/rails/activeresource.git'

gem 'shopify_api'

gem 'ecwid_api', git: 'https://github.com/vishalzambre/ecwid_api.git', branch: 'product-api-with-params'

gem 'chargebee', '~>2'

gem 'js-routes'

gem 'rack-cors', '~> 1.0', require: 'rack/cors'

gem 'remote_lock',  git: 'https://github.com/Nkadze/remote_lock.git'

#sidekiq
gem 'sidekiq'
gem 'sidekiq-scheduler'
gem 'sidekiq-statistic', git: 'https://github.com/davydovanton/sidekiq-statistic.git'
#gem 'sidekiq-unique-jobs'
gem "sidekiq-throttled"
##########

gem 'resque'
gem 'resque-waiting-room'
gem 'resque-scheduler'
gem 'rufus-scheduler', '~> 3.4.2'
gem 'resque_mailer'
gem 'resque-heroku-signals'

#### resque-web specific
gem 'resque-web', require: 'resque_web'
gem 'resque-scheduler-web'
####

gem 'nokogiri' # required by premailer-rails
gem 'premailer-rails'

gem 'recaptcha', require: 'recaptcha/rails'

gem 'heroics'
gem 'platform-api', git: 'https://github.com/heroku/platform-api', branch: 'master', require: false

gem 'ahoy_matey'

gem 'custom_error_message', git: 'https://github.com/nanamkim/custom-err-msg.git'

gem 'rumoji'

# searchkik and gems needed for its performance
gem 'searchkick'
gem 'bonsai-elasticsearch-rails'
gem 'oj'
gem 'typhoeus'
gem 'connection_pool'

gem 'tolk'

gem 'intercom-rails'
gem 'intercom', '~> 3.5.10'

gem 'breadcrumbs_on_rails'

gem 'sentry-raven'

# command pattern implementation
gem 'active_interaction', '~> 3.6'

# state machine implementation
gem 'aasm'

# better handle DB views
gem 'scenic'

# Detect browser (is it a bot?, is it a search engine? No, it's..)
gem 'browser'

# Rewrite routes
gem 'rack-rewrite'

# Feature toggle
gem 'flipper', '= 0.15.0'
gem 'flipper-ui', '= 0.15.0'
gem 'flipper-redis', '= 0.15.0'

# Excel export
gem 'rubyzip', '>= 1.2.1'
gem 'axlsx', git: 'https://github.com/randym/axlsx.git', ref: 'c8ac844'
gem 'axlsx_rails'

gem 'newrelic_rpm'
gem 'scout_apm'

gem 'progress_bar'

# Web code editor in JS
gem 'ace-rails-ap'

# Dealing with money and currency conversion.
gem 'monetize', '~> 1.9.2'
gem 'money-open-exchange-rates', '~> 1.3.0'

# WYSIWYG editor
gem 'tinymce-rails'

group :development, :test do
  gem 'byebug', platform: :mri
  gem 'awesome_print'
  gem 'pry-byebug'
  gem 'pry-rails'

  gem 'factory_bot_rails'
  gem 'to_factory'

  # profiling
  gem 'rack-mini-profiler'
  gem 'flamegraph'
  gem 'ruby-prof', '>= 0.16.0', require: false
  gem 'stackprof'
end

group :development do
  gem 'web-console'

  gem 'derailed_benchmarks'
  gem 'listen', '~> 3.0.5'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'better_errors'
  gem 'binding_of_caller'

  # track n+1 errors
  gem 'bullet', group: 'development'

   # code style
  gem 'pronto'
  gem 'pronto-rubocop', require: false
  gem 'rubocop', '~> 0.63.1', require: false
  gem 'rubocop-rspec', require: false

  # preview emails
  gem 'letter_opener'

  gem 'rails_real_favicon'
end

group :test do
  gem 'minitest-spec-rails'
  gem 'minitest-reporters'
  gem 'minitest-focus'

  gem 'bogus'
  gem 'database_cleaner'

  gem 'simplecov'

  gem 'capybara'
  gem 'capybara-screenshot'
  gem 'webmock'

  gem 'timecop'

  gem 'test-prof'

  gem 'webdrivers'
end

gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

require 'simplecov'

SimpleCov.start 'rails' do
  add_filter '/test'
  add_filter "/config/"
  add_group 'Commands', 'app/commands'
end

ENV['RAILS_ENV'] ||= 'test'
ENV['ELASTICSEARCH_URL'] ||= ENV['BONSAI_URL']

require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

require 'minitest/mock'

require 'bogus/minitest'
require 'bogus/minitest/spec'
require 'aasm/minitest'

require 'database_cleaner'

Bogus.configure do |c|
  c.fake_ar_attributes = true
end

# disable all external network connections during tests
require 'webmock/minitest'

module WebmockConfig
  def self.allowed_urls
    [
      /bonsaisearch.net/,
      /chromedriver/
    ]
  end
end

TestProf.configure do |config|
  config.output_dir = 'tmp/test_prof'
  config.timestamps = true
  config.color = true
end

WebMock.disable_net_connect!(allow_localhost: true, allow: WebmockConfig.allowed_urls)

Dir[Rails.root.join('test/support/**/*.rb')].each { |file| require file }

reporter_options = { color: true, slow_count: 10 }
reporter = Minitest::Reporters::DefaultReporter.new reporter_options
Minitest::Reporters.use! reporter

# searchkik related
Product.reindex
Searchkick.disable_callbacks # and disable callbacks

%w(store_subscription_usages enabled_addons).each do |mat_view|
  ActiveRecord::Base.connection.execute("REFRESH MATERIALIZED VIEW #{mat_view};")
end


DatabaseCleaner.clean_with :truncation
DatabaseCleaner.strategy = :transaction

# enable all flipper featuresk
[:addons, :billing].each do |feature|
  Flipper[feature].enable
end

require 'sidekiq/testing'
Sidekiq::Testing.fake!

class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
end

class ActiveSupport::TestCase
  include FactoryBot::Syntax::Methods
  include ActiveJob::TestHelper

  include Auxillary

  def after_teardown
    Sidekiq::Worker.clear_all
    super
  end
end

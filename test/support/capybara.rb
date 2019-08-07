require 'capybara/minitest'
require 'capybara/rails'
require 'capybara-screenshot/minitest'
require 'webdrivers'

Capybara.javascript_driver = :selenium_chrome
Capybara.server = :puma, { Silent: true }
Capybara::Screenshot.prune_strategy = :keep_last_run

chrome_bin = ENV.fetch('GOOGLE_CHROME_BIN', nil)
chrome_shim = ENV.fetch('GOOGLE_CHROME_SHIM', nil)

Selenium::WebDriver::Chrome.path = chrome_bin if chrome_bin

Capybara.register_driver :selenium_chrome_headless do |app|
  browser_options = ::Selenium::WebDriver::Chrome::Options.new
  browser_options.args << '--headless'
  browser_options.args << '--disable-gpu'
  browser_options.args << '--no-sandbox'
  browser_options.args << '-disable-dev-shm-usage'
  browser_options.binary = chrome_shim if chrome_shim
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: browser_options)
end

class ActionDispatch::IntegrationTest
  include Capybara::DSL
  include Capybara::Minitest::Assertions
  include Capybara::Screenshot::MiniTestPlugin

  def use_javascript_driver
    Capybara.current_driver = :selenium_chrome_headless
  end

  def use_javascript_driver_with_ui
    Capybara.current_driver = :selenium_chrome
  end

  def teardown
    #Capybara.reset_sessions!
    Capybara.use_default_driver
  end
end

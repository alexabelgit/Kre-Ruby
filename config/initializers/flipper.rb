require 'flipper'
require 'flipper/adapters/redis'
require 'flipper/adapters/memory'

BILLING_LAUNCH_DATE = Date.parse(ENV['BILLING_LAUNCH_DATE'] || 'July 15 2018')

class CanAccessFlipperUI
  def self.matches?(request)
    current_user = request.env['warden'].user
    current_user.present? && current_user.respond_to?(:admin?) && current_user.admin?
  end
end

def flipper_redis_adapter
  Redis.current.with do |conn|
    Flipper::Adapters::Redis.new(conn)
  end
end

def flipper_test_adapter
  Flipper::Adapters::Memory.new
end

Flipper.configure do |config|
  config.default do
    if Rails.env.test?
      Flipper.new flipper_test_adapter
    else
      Flipper.new flipper_redis_adapter
    end
  end
end

Flipper.register(:admins) do |store|
  user = store.user
  user.respond_to?(:admin?) && user.admin?
end

Flipper.register(:shopify) do |store|
  store.respond_to?(:shopify?) && store.shopify?
end

Flipper.register(:lemonstand) do |store|
  store.respond_to?(:lemonstand?) && store.lemonstand?
end

Flipper.register(:all_ecwid) do |store|
  store.respond_to?(:ecwid?) && store.ecwid?
end

Flipper.register(:old_ecwid_customers) do |store|
  store.respond_to?(:ecwid?) && store.ecwid? && store.created_at < BILLING_LAUNCH_DATE
end

Flipper.register(:new_ecwid_customers) do |store|
  store.respond_to?(:ecwid?) && store.ecwid? && store.created_at >= BILLING_LAUNCH_DATE
end



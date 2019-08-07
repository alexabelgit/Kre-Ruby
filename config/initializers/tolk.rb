# encoding: utf-8
# See github.com/tolk/tolk for more informations

Tolk.config do |config|
  config.ignore_keys = ['active_interaction', "onboarding", "oauth", "no_records", "kb_articles",
                        "devise", "back", "activerecord.attributes", "date", "datetime", "time", "activerecord.errors.messages",
                        "errors.messages", "number", "support"
  ]

  config.mapping['hi']        = 'Hindi'
  config.mapping['ka']        = 'Georgian'
  config.mapping['tl']        = 'Tagalog'
end

class DatabasePresence
  def self.database_exists?
    ActiveRecord::Base.connection
  rescue ActiveRecord::NoDatabaseError
    false
  else
    true
  end
end

if !Rails.env.test? && ENV['LOAD_TOLK_TRANSLATIONS'].to_b
  if DatabasePresence.database_exists?
    tolk_redis_backend = Redis.current.with { |connection| TolkRedisBackend.new(connection).backend }
    I18n.backend = I18n::Backend::Chain.new(tolk_redis_backend, I18n::Backend::Simple.new)
  end
end

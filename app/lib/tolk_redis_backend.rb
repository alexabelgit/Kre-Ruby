class TolkRedisBackend
  class RedisStore
    PREFIX = 'i18n'.freeze
    def initialize(redis)
      @redis = redis
    end

    def with_prefix(key)
      "#{PREFIX}.#{key}"
    end

    def [](key)
      @redis.get(with_prefix(key)) || ""
    end

    def []=(key, value)
      @redis.set with_prefix(key), value
    end

    def keys
      @redis.keys with_prefix('*')
    end

    def clear_old_entries
      keys_to_delete = keys
      @redis.del(*keys_to_delete) unless keys_to_delete.empty?
    end
  end

  attr_reader :backend
  def initialize(redis)
    redis_store = RedisStore.new(redis)
    redis_store.clear_old_entries

    @backend = I18n::Backend::KeyValue.new redis_store

    Tolk::Locale.secondary_locales.each do |locale|
      @backend.store_translations locale.name, locale.to_hash[locale.name]
    end
  end
end
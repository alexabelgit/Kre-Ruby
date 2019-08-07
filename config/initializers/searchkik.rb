Ethon.logger = Logger.new(nil)
uri   = URI.parse(ENV['REDISCLOUD_URL'] || ENV['REDIS_URL'])
Searchkick.redis = ConnectionPool.new(size: 20) { Redis.new(host: uri.host, port: uri.port, password: uri.password, driver: :hiredis) }

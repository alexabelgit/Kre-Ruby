uri = URI.parse(ENV['REDISCLOUD_URL'] || ENV['REDIS_URL'])
Resque.redis = Redis.new(host: uri.host, port: uri.port, password: uri.password, driver: :hiredis)

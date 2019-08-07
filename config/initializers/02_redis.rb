uri = URI.parse(ENV['REDISCLOUD_URL'] || ENV['REDIS_URL'])
Redis.current = ConnectionPool.new(size: 50) do
  Redis.new(host: uri.host, port: uri.port, password: uri.password, driver: :hiredis)
end

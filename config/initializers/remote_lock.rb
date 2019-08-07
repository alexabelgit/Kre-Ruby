Redis.current.with do |conn|
  $lock = RemoteLock.new(RemoteLock::Adapters::Redis.new(conn))
end

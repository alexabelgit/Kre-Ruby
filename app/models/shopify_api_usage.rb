class ShopifyApiUsage
  attr_reader :store_id, :redis
  ZSET_NAME = 'hc_shopify_usage'.freeze
  SAFE_LIMIT = 30 # when that limit is passed - we switch to 1 worker per store

  def initialize(store_id)
    @store_id = store_id
  end

  def limit_exceeded?
    current > SAFE_LIMIT
  end

  def decrease_by(amount)
    obtain_connection do |conn|
      conn.zincrby ZSET_NAME, -amount, store_id
    end
  end

  def set(value)
    obtain_connection do |conn|
      conn.zadd ZSET_NAME, value, store_id
    end
  end

  def clear
    obtain_connection do |conn|
      conn.zrem ZSET_NAME, store_id
    end
  end

  def current
    obtain_connection do |conn|
      value = conn.zscore ZSET_NAME, store_id
      if value.nil?
        value = 0
        conn.zadd ZSET_NAME, value, store_id unless value
      end
      value
    end
  end

  private

  def obtain_connection(&block)
    Redis.current.with do |conn|
      yield(conn)
    end
  end
end

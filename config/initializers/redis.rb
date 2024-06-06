raise "Prevent monkey patch chaos" if Redis.respond_to?(:with_connection)

class Redis
  raise "Prevent monkey patch chaos" if const_defined?(:CONNECTION_POOL) || const_defined?(:POOL_TIMEOUT) || const_defined?(:REDIS_TIMEOUT)

  POOL_TIMEOUT = 5 # amount of time to wait for a connection if none currently available in the pool
  REDIS_TIMEOUT = 5 # timeout for each individual connection, see https://github.com/redis/redis-rb?tab=readme-ov-file#timeouts

  CONNECTION_POOL = ConnectionPool.new(size: ENV.fetch("RAILS_MAX_THREADS", 5), timeout: POOL_TIMEOUT) do
    redis_connection = new(url: Rails.configuration.x.redis_url, timeout: REDIS_TIMEOUT)
    Redis::Namespace.new(Rails.configuration.x.redis_namespace, redis: redis_connection)
  end

  def self.with_connection(&block)
    CONNECTION_POOL.with(&block)
  end
end

raise "Prevent monkey patch chaos" if Redis.respond_to?(:with_connection)

class Redis
  raise "Prevent monkey patch chaos" if const_defined?(:CONNECTION_POOL)

  CONNECTION_POOL = ConnectionPool.new(size: ENV.fetch("RAILS_MAX_THREADS", 5), timeout: 5) do
    redis_connection = new(url: Rails.configuration.x.redis_url)
    Redis::Namespace.new(Rails.configuration.x.redis_namespace, redis: redis_connection)
  end

  def self.with_connection(&block)
    CONNECTION_POOL.with(&block)
  end
end

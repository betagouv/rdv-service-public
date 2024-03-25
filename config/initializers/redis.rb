raise "Prevent monkey patch" if Redis.respond_to?(:with_connection)

class Redis
  def self.with_connection
    redis_connection = new(url: Rails.configuration.x.redis_url)
    redis_connection = Redis::Namespace.new(Rails.configuration.x.redis_namespace, redis: redis_connection)
    yield(redis_connection)
  ensure
    redis_connection&.close
  end
end

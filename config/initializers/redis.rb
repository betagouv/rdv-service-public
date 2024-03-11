raise "Prevent monkey patch" if Redis.respond_to?(:with_connection)

class Redis
  def self.with_connection
    redis_connection = new(Rails.configuration.x.redis_settings)
    redis_connection = Redis::Namespace.new(Rails.configuration.x.redis_app_namespace, redis: redis_connection)
    yield(redis_connection)
  ensure
    redis_connection&.close
  end
end

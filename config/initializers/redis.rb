raise "Prevent monkey patch" if Redis.respond_to?(:with_connection)

class Redis
  def self.with_connection
    connection = new(url: Rails.configuration.x.redis_url)
    yield(connection)
  ensure
    connection&.close
  end
end

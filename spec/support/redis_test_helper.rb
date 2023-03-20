# frozen_string_literal: true

class RedisTestHelper
  def self.non_expiring_keys
    redis = Redis.new(url: Rails.configuration.x.redis_url)

    non_expiring_keys = redis.keys.select do |key|
      redis.ttl(key) == -1
    end

    redis.flushall
    redis.close

    non_expiring_keys
  end
end

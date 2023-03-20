class ExpectRedisNotToLeak
  def self.check_and_flush_redis!
    redis = Redis.new(url: Rails.configuration.x.redis_url)

    keys = redis.keys

    keys.each do |key|
      if redis.expiretime(key) == -1
        raise "Redis leak risk: the key #{key} has been set without an expiration time"
      end
    end

    redis.flushall
  end
end

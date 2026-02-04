module RedisFileStorable
  extend ActiveSupport::Concern

  class FileNotFoundError < StandardError; end

  def load_file
    compressed_file = Redis.with_connection { |redis| redis.get(redis_file_key) }
    raise FileNotFoundError, "Can't find file at key #{redis_file_key.inspect}" unless compressed_file

    Zlib.inflate(compressed_file)
  end

  def store_file(content)
    transaction do
      update!(computed_at: Time.zone.now)
      compressed_file = Zlib.deflate(content)
      Redis.with_connection do |redis|
        redis.set(redis_file_key, compressed_file)
        redis.expire(redis_file_key, (expires_at - Time.zone.now).seconds.to_i)
      end
    end
  end

  private

  def redis_file_key
    "Export#redis_file_key-#{id}"
  end
end

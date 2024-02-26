class Export < ApplicationRecord
  EXPIRATION_DELAY = 6.hours

  # Relations
  belongs_to :agent

  # Validations
  validates :expires_at, presence: true

  # Hooks
  before_validation { self.expires_at ||= EXPIRATION_DELAY.from_now }

  # Scopes
  scope :recent, -> { where("created_at > ?", 2.weeks.ago) }

  enum export_type: {
    rdv_export: :rdv_export,
    participations_export: :participations_export,
  }

  def expired?
    expires_at <= Time.zone.now
  end

  def load_content
    redis_connection = Redis.new(url: Rails.configuration.x.redis_url)
    gzipped_file = redis_connection.get(content_redis_key)
    Zlib.inflate(gzipped_file)
  ensure
    redis_connection&.close
  end

  def store_content(content)
    redis_connection = Redis.new(url: Rails.configuration.x.redis_url)
    gzipped_file = Zlib.deflate(content)
    redis_connection.set(content_redis_key, gzipped_file)
    redis_connection.expire(content_redis_key, (expires_at - Time.zone.now).seconds.to_i)
  ensure
    redis_connection&.close
  end

  private

  def content_redis_key
    "Export#content_redis_key-#{id}"
  end
end

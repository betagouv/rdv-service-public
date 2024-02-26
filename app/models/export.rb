class Export < ApplicationRecord
  # Relations
  belongs_to :agent

  # Validations
  validates :expires_at, presence: true

  # Hooks
  before_validation { self.expires_at ||= 6.hours.from_now }

  # Scopes
  scope :recent, -> { where("created_at > ?", 2.weeks.ago) }

  enum export_type: {
    rdv_export: :rdv_export,
    participations_export: :participations_export,
  }

  def load_content
    redis_connection = Redis.new(url: Rails.configuration.x.redis_url)
    encoded_content = redis_connection.get(content_redis_key)
    Base64.decode64(encoded_content)
  ensure
    redis_connection&.close
  end

  def store_content(content)
    encoded_content = Base64.encode64(content)

    redis_connection = Redis.new(url: Rails.configuration.x.redis_url)
    redis_connection.set(content_redis_key, encoded_content)
    redis_connection.expire(content_redis_key, (expires_at - Time.zone.now).seconds.to_i)
  ensure
    redis_connection&.close
  end

  private

  def content_redis_key
    "export-file-#{id}"
  end
end

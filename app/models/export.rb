class Export < ApplicationRecord
  EXPIRATION_DELAY = 6.hours

  STATUS_PENDING = :pending
  STATUS_EXPIRED = :expired
  STATUS_AVAILABLE = :available

  RDV_EXPORT = "rdv_export".freeze
  PARTICIPATIONS_EXPORT = "participations_export".freeze

  enum export_type: {
    RDV_EXPORT => RDV_EXPORT,
    PARTICIPATIONS_EXPORT => PARTICIPATIONS_EXPORT,
  }

  # Relations
  belongs_to :agent

  # Validations
  validates :expires_at, :file_name, presence: true

  # Hooks
  before_validation { self.expires_at ||= EXPIRATION_DELAY.from_now }

  # Scopes
  scope :recent, -> { where("created_at > ?", 2.weeks.ago) }

  def to_s
    type = case export_type
           when RDV_EXPORT
             "de RDV"
           when PARTICIPATIONS_EXPORT
             "de RDV par usager"
           end
    "Export #{type} du #{I18n.l(created_at, format: :dense)}"
  end

  def expired?
    expires_at <= Time.zone.now
  end

  def available?
    computed_at && !expired?
  end

  def computed?
    !!computed_at
  end

  def status
    if expired?
      STATUS_EXPIRED
    elsif computed_at
      STATUS_AVAILABLE
    else
      STATUS_PENDING
    end
  end

  def load_file
    Redis.with_connection do |redis|
      compressed_file = redis.get(content_redis_key)
      Zlib.inflate(compressed_file)
    end
  end

  def store_file(content)
    transaction do
      update!(computed_at: Time.zone.now)
      Redis.with_connection do |redis|
        compressed_file = Zlib.deflate(content)
        redis.set(content_redis_key, compressed_file)
        redis.expire(content_redis_key, (expires_at - Time.zone.now).seconds.to_i)
      end
    end
  end

  private

  def content_redis_key
    "Export#content_redis_key-#{id}"
  end
end

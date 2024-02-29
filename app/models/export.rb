class Export < ApplicationRecord
  EXPIRATION_DELAY = 6.hours

  STATUS_PENDING = :pending
  STATUS_EXPIRED = :expired
  STATUS_AVAILABLE = :available

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

  def to_s
    type = case export_type
           when self.class.export_types[:rdv_export]
             "de RDV"
           when self.class.export_types[:participations_export]
             "de RDV par usager"
           else
             raise "oh no"
           end
    "Export #{type} du #{I18n.l(created_at, format: :dense)}"
  end

  def expired?
    expires_at <= Time.zone.now
  end

  def available?
    computed_at && !expired?
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

  def load_content
    Redis.with_connection do |redis|
      gzipped_file = redis.get(content_redis_key)
      Zlib.inflate(gzipped_file)
    end
  end

  def store_content(content)
    transaction do
      update!(computed_at: Time.zone.now)
      Redis.with_connection do |redis|
        gzipped_file = Zlib.deflate(content)
        redis.set(content_redis_key, gzipped_file)
        redis.expire(content_redis_key, (expires_at - Time.zone.now).seconds.to_i)
      end
    end
  end

  private

  def content_redis_key
    "Export#content_redis_key-#{id}"
  end
end

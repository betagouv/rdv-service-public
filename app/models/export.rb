class Export < ApplicationRecord
  include RedisFileStorable

  EXPIRATION_DELAY = 6.hours

  STATUS_PENDING = :pending
  STATUS_EXPIRED = :expired
  STATUS_AVAILABLE = :available

  RDV_EXPORT = "rdv_export".freeze
  PARTICIPATIONS_EXPORT = "participations_export".freeze

  enum :export_type, {
    RDV_EXPORT => RDV_EXPORT,
    PARTICIPATIONS_EXPORT => PARTICIPATIONS_EXPORT,
  }

  # Relations
  belongs_to :agent

  # Validations
  validates :expires_at, :file_name, presence: true

  # Hooks
  after_initialize { self.expires_at ||= EXPIRATION_DELAY.from_now }

  # Scopes
  scope :recent, -> { where("created_at > ?", 2.weeks.ago) }

  def to_s
    "#{I18n.t("export_type.#{export_type}")} du #{I18n.l(created_at, format: :dense)}"
  end

  def available?
    status == STATUS_AVAILABLE
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

  def organisations
    Organisation.where(id: organisation_ids)
  end

  private

  def expired?
    expires_at <= Time.zone.now
  end

  def redis_file_key
    "Export#redis_file_key-#{id}"
  end
end

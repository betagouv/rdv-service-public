class ExternalCalendarSyncExecution < ApplicationRecord
  # Relations
  belongs_to :agent
  has_many :logs, -> { order(:emitted_at) }, class_name: "ExternalCalendarSyncExecutionsLog", inverse_of: :external_calendar_sync_execution, dependent: :destroy

  # Validations
  validates :started_at, presence: true
  validate :ended_at_cant_be_before_started_at

  def status
    if ended_at?
      successful ? "Succès" : "Échec"
    else
      "En cours"
    end
  end

  def duration
    ended_at - started_at if started_at && ended_at
  end

  def start!
    self.started_at = Time.zone.now
    save!
  end

  def log(message)
    logs.create!(message:, emitted_at: Time.zone.now)
  end

  def flush!(successful:)
    self.successful = successful
    self.ended_at = Time.zone.now
    save!
  end

  private

  def ended_at_cant_be_before_started_at
    return unless started_at && ended_at

    if started_at > ended_at
      errors.add(:ended_at, :cant_be_before_started_at)
    end
  end
end

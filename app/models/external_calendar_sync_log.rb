class ExternalCalendarSyncLog < ApplicationRecord
  belongs_to :agent

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
    self.text_logs ||= []
    text_logs << message
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

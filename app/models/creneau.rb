class Creneau
  include ActiveModel::Model
  include Comparable

  attr_accessor :starts_at, :lieu_id, :motif, :agent

  delegate :full_name, to: :lieu, prefix: true, allow_nil: true

  def build_rdv
    Rdv.new(
      agents: [agent],
      duration_in_min: duration_in_min,
      starts_at: starts_at,
      organisation: motif.organisation,
      motif: motif,
      lieu: lieu
    )
  end

  def ends_at
    starts_at + duration_in_min.minutes
  end

  def range
    starts_at...ends_at
  end

  def lieu
    Lieu.find(lieu_id) if lieu_id.present?
  end

  def duration_in_min
    motif.default_duration_in_min
  end

  # Required by the Comparable module
  def <=>(other)
    starts_at <=> other.starts_at
  end

  def respects_max_public_booking_delay?
    starts_at <= (Time.zone.now + motif.max_public_booking_delay.seconds)
  end
end

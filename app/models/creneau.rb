class Creneau
  include ActiveModel::Model

  attr_accessor :starts_at, :lieu_id, :motif, :agent_id, :agent_name

  def ends_at
    starts_at + duration_in_min.minutes
  end

  def range
    starts_at...ends_at
  end

  def lieu
    Lieu.find(lieu_id)
  end

  def agent
    Agent.find(agent_id)
  end

  def duration_in_min
    motif.default_duration_in_min
  end

  def respects_min_booking_delay?
    starts_at >= (Time.zone.now + motif.min_booking_delay.seconds)
  end

  def respects_max_booking_delay?
    starts_at <= (Time.zone.now + motif.max_booking_delay.seconds)
  end

  def respects_booking_delays?
    respects_min_booking_delay? && respects_max_booking_delay?
  end

  def overlapping_rdvs_or_absences(rdvs_or_absences)
    rdvs_or_absences.select do |r_o_a|
      (starts_at < r_o_a.ends_at && r_o_a.ends_at < ends_at) ||
        (starts_at < r_o_a.starts_at && r_o_a.starts_at < ends_at) ||
        (r_o_a.starts_at <= starts_at && ends_at <= r_o_a.ends_at)
    end.sort_by(&:ends_at).reverse
  end

  def overlaps_jour_ferie?
    JoursFeriesService.all_in_date_range(starts_at.to_date..ends_at.to_date).any?
  end

  private

  def date_range
    starts_at.to_date...(starts_at.to_date + 1.day)
  end
end

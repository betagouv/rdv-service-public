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

  def duration_in_min
    motif.default_duration_in_min
  end

  def available_plages_ouverture
    plages_ouverture = PlageOuverture.for_motif_and_lieu_from_date_range(motif.name, lieu, date_range)
    plages_ouverture.select do |p|
      occurence_match_creneau = p.occurences_ranges_for(date_range).any? do |occurences_range|
        (occurences_range.begin <= range.end) && (range.begin <= occurences_range.end)
      end
      rdvs = p.agent.rdvs.where(starts_at: date_range).active
      absences_occurrences = p.agent.absences.flat_map { |a| a.occurences_for(date_range) }

      occurence_match_creneau && available_with_rdvs_and_absences?(rdvs, absences_occurrences)
    end
  end

  def available?
    available_plages_ouverture.any?
  end

  def available_with_rdvs_and_absences?(rdvs, absences, for_agents: false)
    !overlaps_rdv_or_absence?(rdvs) &&
      !overlaps_rdv_or_absence?(absences) &&
      !overlaps_jour_ferie? &&
      (for_agents || respects_booking_delays?)
  end

  def to_rdv_for_user(user)
    agent = available_plages_ouverture.sample&.agent

    return unless agent.present?

    Rdv.new(agents: [agent],
      duration_in_min: duration_in_min,
      starts_at: starts_at,
      organisation: motif.organisation,
      motif: motif,
      location: lieu.address,
      users: [user])
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

  def overlaps_rdv_or_absence?(rdvs_or_absences)
    rdvs_or_absences.select do |r_o_a|
      (starts_at < r_o_a.ends_at && r_o_a.ends_at < ends_at) ||
        (starts_at < r_o_a.starts_at && r_o_a.starts_at < ends_at) ||
        (r_o_a.starts_at <= starts_at && ends_at <= r_o_a.ends_at)
    end.any?
  end

  def overlaps_jour_ferie?
    JoursFeriesService.all_in_date_range(starts_at.to_date..ends_at.to_date).any?
  end

  def self.next_availability_for_motif_and_lieu(motif_name, lieu, from)
    available_creneau = nil
    from.step(from + 6.months, 7).find do |date|
      creneaux = CreneauxBuilderService.new(motif_name, lieu, date..(date + 7.days)).perform
      available_creneau = creneaux.first if creneaux.any?
    end
    available_creneau
  end

  private

  def date_range
    starts_at.to_date...(starts_at.to_date + 1.day)
  end
end

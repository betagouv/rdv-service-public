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
      absences = p.agent.absences

      occurence_match_creneau && available_with_rdvs_and_absences?(rdvs, absences)
    end
  end

  def available?
    available_plages_ouverture.any?
  end

  def available_with_rdvs_and_absences?(rdvs, absences)
    !overlaps_rdv_or_absence?(rdvs) &&
      !overlaps_rdv_or_absence?(absences) &&
      !too_late?
  end

  def to_rdv_for_user(user)
    agent = available_plages_ouverture.sample&.agent

    return unless agent.present?

    Rdv.new(name: "Rdv en ligne",
      agents: [agent],
      duration_in_min: duration_in_min,
      starts_at: starts_at,
      organisation: motif.organisation,
      motif: motif,
      location: lieu.address,
      users: [user])
  end

  def too_late?
    (starts_at - motif.min_booking_delay.seconds) < Time.zone.now
  end

  def overlaps_rdv_or_absence?(rdvs_or_absences)
    rdvs_or_absences.select do |r_o_a|
      (starts_at < r_o_a.ends_at && r_o_a.ends_at < ends_at) ||
        (starts_at < r_o_a.starts_at && r_o_a.starts_at < ends_at) ||
        (r_o_a.starts_at <= starts_at && ends_at <= r_o_a.ends_at)
    end.any?
  end

  def self.for_motif_and_lieu_from_date_range(motif_name, lieu, inclusive_date_range, for_agents = false, agent_ids = nil)
    plages_ouverture = PlageOuverture.for_motif_and_lieu_from_date_range(motif_name, lieu, inclusive_date_range, agent_ids)
    inclusive_datetime_range = (inclusive_date_range.begin.to_time)..(inclusive_date_range.end.end_of_day)

    results = plages_ouverture.flat_map do |po|
      rdvs = po.agent.rdvs.where(starts_at: inclusive_datetime_range).active
      absences = po.agent.absences
      motifs = if for_agents
                 po.motifs
               else
                 po.motifs.online
               end

      motifs.flat_map do |motif|
        creneaux_nb = po.time_shift_duration_in_min / motif.default_duration_in_min
        po.occurences_for(inclusive_date_range).flat_map do |occurence_time|
          (0...creneaux_nb).map do |n|
            creneau = Creneau.new(
              starts_at: (po.start_time + (n * motif.default_duration_in_min * 60)).on(occurence_time),
              lieu_id: lieu.id,
              motif: motif
            )
            if for_agents
              creneau.agent_id = po.agent_id
              creneau.agent_name = po.agent.short_name
            end
            creneau.available_with_rdvs_and_absences?(rdvs, absences) ? creneau : nil
          end.compact
        end
      end
    end

    if for_agents
      results.uniq { |c| [c.starts_at, c.agent_id] }.sort_by(&:starts_at)
    else
      results.uniq(&:starts_at).sort_by(&:starts_at)
    end
  end

  private

  def date_range
    starts_at.to_date...(starts_at.to_date + 1.day)
  end
end

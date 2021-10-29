# frozen_string_literal: true

# https://pad.incubateur.net/jftuVsrKTsKbn3ay8AoL0Q?edit
module SlotBuilder
  # À faire avant, au moment de jouer avec le motifs
  # @for_agents ? motifs : motifs.reservable_online

  def self.available_slots(motif, date_range, organisation, off_days, *options)
    # options :  { agents: [], lieux: [] }
    plage_ouvertures = plage_ouvertures_for(motif, date_range, organisation, options)
    free_times = free_times_from(plage_ouvertures, date_range, off_days) # dépendance sur RDV et Absence
    slots_for(free_times, motif)
  end

  # TODO: Pourrait être un scope de plage d'ouverture. Quel nom ?
  def self.plage_ouvertures_for(motif, date_range, organisation, *_options)
    # Pas de solution simple pour prendre en compte le cas d'exclusion des PO qui sont sur une journée, sans réccurrence, entre la date de début du range et aujourd'hui (elles ne sont pas expirées).
    # En prenant le first_day dans le range on les exclus, mais on exclus aussi les PO récurrente dont le first_day est dans le passée et la réccurence encore active
    # En prenant le first_day < à la date de fin du range on récupère les PO qui sont entre la date de début du range et aujourd'hui.
    # En attendant, je me dit que ce cas est mineur et que ça fera sans doute pas beaucoup de PO.
    # Elles seront filtrées plus tard.
    organisation.plage_ouvertures.joins(:motifs).where("motifs.id": motif.id).not_expired.where("first_day < ?", date_range.end)
  end

  def self.free_times_from(plage_ouvertures, date_range, off_days) # récupération d'un ActiveRecord::Query sur les PO
    free_times = {}
    plage_ouvertures.each do |plage_ouverture|
      free_times[plage_ouverture] = calculate_free_times(plage_ouverture, date_range, off_days)
    end
    free_times
    # retourner plutôt un enumérator histoire d'être lazy ?
  end

  def self.calculate_free_times(plage_ouverture, date_range, _off_days)
    # soustraire les RDV et les absences de l'agent de la PO sur la période donnée
    occurrences = plage_ouverture.occurrences_for(date_range)
    return [] if occurrences.empty?

    [occurrences.first.starts_at..occurrences.first.ends_at]
  end

  def self.slots_for(plage_ouverture_free_times, motif)
    slots = []
    plage_ouverture_free_times.each do |plage_ouverture, free_times|
      free_times.each do |free_time|
        slots += calculate_slots(free_time, motif) do |starts_at|
          Creneau.new(
            starts_at: starts_at,
            motif: motif,
            lieu_id: plage_ouverture.lieu,
            agent_id: plage_ouverture.agent_id,
            agent_name: plage_ouverture.agent.full_name
          )
        end
      end
    end
    slots
  end

  def self.calculate_slots(free_time, motif, slots = [], &build_creneau)
    try_end_time = free_time.begin + motif.default_duration_in_min.minutes
    if free_time.end > try_end_time
      new_free_time = (free_time.begin + motif.default_duration_in_min.minutes)..free_time.end
      slots << build_creneau.call(free_time.begin) if block_given?
      calculate_slots(new_free_time, motif, slots, &build_creneau)
    end
    slots
  end
end

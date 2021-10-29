# frozen_string_literal: true

# https://pad.incubateur.net/jftuVsrKTsKbn3ay8AoL0Q?edit
module SlotBuilder
  # À faire avant, au moment de jouer avec le motifs
  # @for_agents ? motifs : motifs.reservable_online

  def self.available_slots(motif, date_range, organisation, off_days, agents: [], lieux: [])
    plage_ouvertures = plage_ouvertures_for(motif, date_range, organisation, { agents: [], lieux: [] })
    free_times = free_times_from(plage_ouvertures, date_range, off_days) # dépendance sur RDV et Absence
    slots_for(free_times, motif)
  end

  def self.plage_ouvertures_for(motif, _date_range, organisation, *_options)
    organisation.plage_ouvertures.joins(:motifs).where("motifs.id": motif.id).sample(1)
    # pas réccurrente dont les dates soient dedans
    # réccurrentes avec une date de début avant et la date de fin après le date range
    # réccurrentes avec une date de début sans date de fin et avant le date range
    # Permet de lister les PO pontentiellement concernées en restant lazy
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
            motif: motif,
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

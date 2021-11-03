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
    #
    # avec un OR on pourrait prendre en compte les deux cas (avec et sans recurrence)
    #
    # pour exclure les PO dont la récurrence termine avant le date range de construction de créneau,
    # il faudrait avoir les éléments de la récurrence accessible pour une requete direct : ici surtout la date de fin de récurrence.
    #
    # Inclure les RDV et les Absences de l'agent pour pouvoir les soustraires dans freetimes
    #
    # TODO utiliser les scopes défini dans la PR #1839 https://github.com/betagouv/rdv-solidarites.fr/pull/1839 quand elle sera dispo
    #
    # TODO filtre sur le lieu des options
    #
    organisation.plage_ouvertures.joins(:motifs).where("motifs.id": motif.id).not_expired.where("first_day < ?", date_range.end)
  end

  def self.free_times_from(plage_ouvertures, date_range, off_days)
    free_times = {}
    plage_ouvertures.each do |plage_ouverture|
      free_times[plage_ouverture] = calculate_free_times(plage_ouverture, date_range, off_days)
    end
    free_times
    # retourner plutôt un enumérator histoire d'être lazy ?
  end

  def self.calculate_free_times(plage_ouverture, date_range, _off_days)
    # TODO: soustraire les RDV et les absences de l'agent de la PO sur la période donnée
    occurrences = plage_ouverture.occurrences_for(date_range)
    return [] if occurrences.empty?

    # TODO: prendre en considération qu'il peut y avoir plusieurs occurrence
    base_range = occurrences.first.starts_at..occurrences.first.ends_at
    ranges = [base_range]

    # On soustrait les RDV du temps disponible
    rdvs = plage_ouverture.agent.rdvs.where(starts_at: date_range).or(plage_ouverture.agent.rdvs.where(ends_at: date_range))
    rdvs.each do |rdv|
      # TODO: manque le cas du RDv qui fini après la PO
      ranges = if base_range.begin <= rdv.starts_at
                 # RDV starts in range
                 [base_range.begin..rdv.starts_at, rdv.ends_at..base_range.end]
               else
                 # RDV starts before range
                 [rdv.ends_at..base_range.end]
               end
    end

    # TODO: manque les absences / indisponibilités
    ranges.select { |r| ((r.end.to_i - r.begin.to_i) / 60).positive? }
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

  def self.calculate_slots(free_time, motif, &build_creneau)
    return [] unless block_given?

    slots = []
    possible_slot_time = free_time.begin..(free_time.begin + motif.default_duration_in_min.minutes)
    while possible_slot_time.end <= free_time.end
      slots << build_creneau.call(possible_slot_time.begin)
      possible_slot_time = possible_slot_time.end..(possible_slot_time.end + motif.default_duration_in_min.minutes)
    end
    slots
  end
end

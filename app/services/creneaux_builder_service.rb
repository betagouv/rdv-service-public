class CreneauxBuilderService
  def initialize(motif_name, lieu, inclusive_date_range, for_agents: false, agent_ids: nil)
    @motif_name = motif_name
    @lieu = lieu
    @inclusive_date_range = inclusive_date_range
    @for_agents = for_agents
    @agent_ids = agent_ids
  end

  def perform
    plages_ouverture = PlageOuverture.for_motif_and_lieu_from_date_range(@motif_name, @lieu, @inclusive_date_range, @agent_ids)
    inclusive_datetime_range = (@inclusive_date_range.begin.to_time)..(@inclusive_date_range.end.end_of_day)

    results = plages_ouverture.flat_map do |po|
      motifs = po.motifs.where(name: @motif_name).active
      motifs = motifs.online unless @for_agents

      creneaux = motifs.flat_map do |motif|
        creneaux_nb = po.time_shift_duration_in_min / motif.default_duration_in_min
        po.occurences_for(@inclusive_date_range).flat_map do |occurence|
          (0...creneaux_nb).map do |n|
            Creneau.new(
              starts_at: (po.start_time + (n * motif.default_duration_in_min * 60)).on(occurence.starts_at),
              lieu_id: @lieu.id,
              motif: motif,
              agent_id: (po.agent_id if @for_agents),
              agent_name: (po.agent.short_name if @for_agents)
            )
          end
        end
      end

      rdvs = po.agent.rdvs.where(starts_at: inclusive_datetime_range).active
      absences_occurrences = po.agent.absences.flat_map { |a| a.occurences_for(inclusive_datetime_range) }

      creneaux.select { |c| c.available_with_rdvs_and_absences?(rdvs, absences_occurrences, for_agents: @for_agents) }
    end

    uniq_by = @for_agents ? ->(c) { [c.starts_at, c.agent_id] } : ->(c) { c.starts_at }
    results.uniq(&uniq_by).sort_by(&:starts_at)
  end
end

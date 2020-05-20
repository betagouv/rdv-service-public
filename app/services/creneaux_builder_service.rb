class CreneauxBuilderService < BaseService
  def initialize(motif_name, lieu, inclusive_date_range, **options)
    @motif_name = motif_name
    @lieu = lieu
    @inclusive_date_range = inclusive_date_range
    @for_agents = options.fetch(:for_agents, false)
    @agent_ids = options.fetch(:agent_ids, nil)
    @agent_name = options.fetch(:agent_name, false)
  end

  def perform
    creneaux = plages_ouvertures.flat_map { |po| creneaux_for_plage_ouverture(po) }
    creneaux = creneaux.select { |c| c.starts_at >= Time.zone.now }
    uniq_by = @for_agents ? ->(c) { [c.starts_at, c.agent_id] } : ->(c) { c.starts_at }
    creneaux.uniq(&uniq_by).sort_by(&:starts_at)
  end

  private

  def plages_ouvertures
    @plages_ouvertures ||= PlageOuverture.for_motif_and_lieu_from_date_range(@motif_name, @lieu, @inclusive_date_range, @agent_ids)
  end

  def inclusive_datetime_range
    @inclusive_datetime_range ||= (@inclusive_date_range.begin.to_time)..(@inclusive_date_range.end.end_of_day)
  end

  def motifs_for_plage_ouverture(plage_ouverture)
    motifs = plage_ouverture.motifs.where(name: @motif_name).active
    @for_agents ? motifs : motifs.online
  end

  def creneaux_for_plage_ouverture(plage_ouverture)
    motifs = motifs_for_plage_ouverture(plage_ouverture)
    creneaux = motifs.flat_map { |motif| creneaux_for_plage_ouverture_and_motif(plage_ouverture, motif) }
    rdvs = plage_ouverture.agent.rdvs.where(starts_at: inclusive_datetime_range).active
    absences_occurrences = plage_ouverture.agent.absences.flat_map { |a| a.occurences_for(inclusive_datetime_range) }
    creneaux.select { |c| c.available_with_rdvs_and_absences?(rdvs, absences_occurrences, for_agents: @for_agents) }
  end

  def creneaux_for_plage_ouverture_and_motif(plage_ouverture, motif)
    creneaux_nb = plage_ouverture.time_shift_duration_in_min / motif.default_duration_in_min
    plage_ouverture.occurences_for(@inclusive_date_range).flat_map do |occurence|
      (0...creneaux_nb).map do |n|
        Creneau.new(
          starts_at: (plage_ouverture.start_time + (n * motif.default_duration_in_min * 60)).on(occurence.starts_at),
          lieu_id: @lieu.id,
          motif: motif,
          agent_id: (plage_ouverture.agent_id if @for_agents),
          agent_name: (plage_ouverture.agent.short_name if @for_agents || @agent_name)
        )
      end
    end
  end
end

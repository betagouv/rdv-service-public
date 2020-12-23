class FindAvailabilityService < BaseService
  def initialize(motif_name, lieu, from, **creneaux_builder_options)
    @motif_name = motif_name
    @lieu = lieu
    @from = from
    @creneaux_builder_options = creneaux_builder_options
  end

  def perform
    available_creneau = nil
    @from.step(@from + 6.months, 7).find do |date|
      inclusive_date_range = date..(date + 7.days)
      uniq_by = @for_agents ? ->(c) { [c.starts_at, c.agent_id] } : ->(c) { c.starts_at }
      available_creneau = plages_ouverture_and_motif_pairs
        .flat_map { |po, motif| creneaux_for_plage_ouverture_and_motif(po, motif, inclusive_date_range) }
        .select { |c| c.starts_at >= Time.zone.now }
        .uniq(&uniq_by)
        .min_by(&:starts_at)
    end
    available_creneau
  end

  private

  def plages_ouverture_and_motif_pairs
    @plages_ouverture_and_motif_pairs ||= plages_ouvertures
      .flat_map { |po| motifs_for_plage_ouverture(po).map { [po, _1] } }
  end

  def motifs_for_plage_ouverture(plage_ouverture)
    motifs = plage_ouverture.motifs.where(name: @motif_name).active
    motifs = motifs.where(location_type: @motif_location_type) if @motif_location_type.present?
    @for_agents ? motifs : motifs.reservable_online
  end

  def creneaux_for_plage_ouverture_and_motif(plage_ouverture, motif, inclusive_date_range)
    plage_ouverture.occurences_for(inclusive_date_range).flat_map do |occurence|
      [
        CreneauxBuilderForDateService
          .new(plage_ouverture, motif, occurence.starts_at.to_date, @lieu, inclusive_date_range: inclusive_date_range, **@creneaux_builder_options)
          .next_creneaux_enumerator
          .next
      ]
    rescue StopIteration
      []
    end.compact
  end

  def plages_ouvertures
    @plages_ouvertures ||= CreneauxBuilderService
      .new(@motif_name, @lieu, @from..(@from + 7.days))
      .plages_ouvertures
  end
end

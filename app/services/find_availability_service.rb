class FindAvailabilityService < BaseService
  include HasPlageOuverturesConcern

  def initialize(motif_name, lieu, from, **options)
    @motif_name = motif_name
    @lieu = lieu
    @from = from
    @for_agents = options.fetch(:for_agents, false)
    @agent_ids = options.fetch(:agent_ids, nil)
    @motif_location_type = options.fetch(:motif_location_type, nil)
    @creneaux_builder_options = options
  end

  def perform
    plages_ouvertures
      .flat_map { |po| motifs_for_plage_ouverture(po).map { [po, _1] } }
      .map { |po, motif| first_creneau_for_plage_ouverture_and_motif(po, motif, date_range) }
      .compact
      .select { |c| c.starts_at >= Time.zone.now } # should be moved in creneau validation or stg
      .min_by(&:starts_at)
  end

  private

  def date_range
    (@from..@from + 6.months)
  end

  def motifs_for_plage_ouverture(plage_ouverture)
    motifs = plage_ouverture.motifs.where(name: @motif_name).active
    motifs = motifs.where(location_type: @motif_location_type) if @motif_location_type.present?
    @for_agents ? motifs : motifs.reservable_online
  end

  def first_creneau_for_plage_ouverture_and_motif(*args)
    get_creneau_for_plage_ouverture_and_motif_enum(*args).next
  rescue StopIteration
    nil
  end

  def get_creneau_for_plage_ouverture_and_motif_enum(plage_ouverture, motif, date_range)
    Enumerator.new do |enum|
      plage_ouverture.occurences_for(date_range).map do |occurence|
        enum << CreneauxBuilderForDateService
          .new(plage_ouverture, motif, occurence.starts_at.to_date, @lieu, **@creneaux_builder_options)
          .next_creneaux_enumerator
          .next
      rescue StopIteration
        nil
      end.compact.first
    end
  end
end

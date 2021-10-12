# frozen_string_literal: true

class CreneauxBuilderService < BaseService
  def initialize(motif_name, lieu, inclusive_date_range, **options)
    @motif_name = motif_name
    @lieu = lieu
    @inclusive_date_range = inclusive_date_range
    @options = options
    @for_agents = options.fetch(:for_agents, false)
    @agent_ids = options.fetch(:agent_ids, nil)
    @agent_name = options.fetch(:agent_name, false)
    @motif_location_type = options.fetch(:motif_location_type, nil)
    @plages_ouvertures = options[:plages_ouvertures]
    @service = options[:service]
  end

  def perform
    # NOTE: LOOP 2/3 We flatten many loops here.
    # * plage_ouvertures
    #   * creneaux, which are actually built on
    #   * motifs
    #     * creneaux, which are actually built on
    #     * occurences of the plage_ouverture
    creneaux = plages_ouvertures.flat_map { |po| creneaux_for_plage_ouverture(po) }
    creneaux = creneaux.select { |c| c.starts_at >= Time.zone.now }
    uniq_by = @for_agents ? ->(c) { [c.starts_at, c.agent_id] } : ->(c) { c.starts_at }
    creneaux.uniq(&uniq_by).sort_by(&:starts_at)
  end

  def plages_ouvertures # NOTE: this is cached and reused in findavailabilityservice
    @plages_ouvertures ||= PlageOuverture
      .not_expired_for_motif_name_and_lieu(@motif_name, @lieu)
      .where(({ agent_id: @agent_ids } unless @agent_ids.nil?))
      .where(({ motifs: { location_type: @motif_location_type } } if @motif_location_type.present?))
      .where(({ motifs: { service: @service } } if @service.present?))
  end

  private

  def motifs_for_plage_ouverture(plage_ouverture)
    # NOTE: Is this cacheable for plage_ouverture.motifs?
    # NOTE: Because things are clumsy, we’re searching by motif_name even though we’re being passed an explicit motif
    # I think This means if we have several motifs of the same name, but location_name is different, both motifs are returned.
    motifs = plage_ouverture.motifs.where(name: @motif_name).active
    motifs = motifs.where(location_type: @motif_location_type) if @motif_location_type.present?
    @for_agents ? motifs : motifs.reservable_online
  end

  def creneaux_for_plage_ouverture(plage_ouverture)
    motifs_for_plage_ouverture(plage_ouverture) # here is the query for motifs for a given plage_ouverture
      .flat_map { creneaux_for_plage_ouverture_and_motif(plage_ouverture, _1) } # loops on motifs
  end

  def creneaux_for_plage_ouverture_and_motif(plage_ouverture, motif)
    # NOTE: LOOP 3/4 Let’s loop over the PO occurences (limited to the range)
    plage_ouverture.occurrences_for(@inclusive_date_range).flat_map do |occurrence|
      CreneauxBuilderForDateService
        .perform_with(plage_ouverture, motif, occurrence.starts_at.to_date, @lieu, inclusive_date_range: @inclusive_date_range, **@options)
    end
  end
end

class Users::GeoSearch
  def initialize(departement:, city_code: nil, street_ban_id: nil)
    @departement = departement
    @city_code = city_code
    @street_ban_id = street_ban_id
  end

  def attributed_organisations
    @attributed_organisations ||= Organisation.attributed_to_sectors(sectors: matching_sectors)
  end

  def departement_organisations
    @departement_organisations ||= Organisation.joins(:territory).where(territories: { departement_number: @departement })
  end

  def most_relevant_organisations
    @most_relevant_organisations ||= Organisation.attributed_to_sectors(sectors: matching_sectors, most_relevant: true)
  end

  def attributed_agents_by_organisation
    @attributed_agents_by_organisation ||= matching_sectors
      .map { |sector| sector.attributions.level_agent.includes(:agent).to_a }
      .flatten
      .group_by(&:organisation)
      .transform_values { |attributions| attributions.map(&:agent) }
  end

  def matching_zones
    return nil if @city_code.nil?

    @matching_zones ||= 
      matching_zones_cities_arel.or(matching_zones_streets_arel)
  end

  def matching_sectors
    @matching_sectors ||= Sector.where(id: matching_zones&.pluck(:sector_id))
  end

  def available_services
    @available_services ||= Service.where(id: available_motifs.pluck(:service_id).uniq)
  end

  def available_motifs
    @available_motifs ||= available_motifs_arels.reduce(:or).ordered_by_name
  end

  def attributions_count
    attributed_organisations.count + attributed_agents_by_organisation.count
  end

  def attributions?
    attributions_count.positive?
  end

  def available_motifs_from_attributed_organisation(organisation)
    available_motifs_base
      .sectorisation_level_organisation
      .where(organisation_id: organisation.id)
      .distinct
  end

  def available_motifs_from_attributed_agent(agent, organisation)
    available_individual_motifs_from_attributed_agent_arel(agent, organisation).distinct
  end

  def available_motifs_from_departement_organisations
    available_motifs_from_departement_organisations_arel.distinct
  end

  private

  def matching_zones_cities_arel
    Zone.cities.includes(:sector).where(city_code: @city_code)
  end

  def matching_zones_streets_arel
    return Zone.includes(:sector).none if @street_ban_id.blank?

    Zone.streets.includes(:sector).where(street_ban_id: @street_ban_id)
  end

  def available_motifs_arels
    [
      available_motifs_from_departement_organisations_arel,
      available_motifs_from_attributed_organisations_arel,
      available_motifs_from_attributed_agents_arel,
    ]
  end

  def available_motifs_from_departement_organisations_arel
    @available_motifs_from_departement_organisations_arel ||= available_motifs_base
      .sectorisation_level_departement
      .where(organisations: { id: departement_organisations.pluck(:id) })
  end

  def available_motifs_from_attributed_organisations_arel
    @available_motifs_from_attributed_organisations_arel ||= available_motifs_base
      .sectorisation_level_organisation
      .where(organisations: { id: attributed_organisations.pluck(:id) })
  end

  def available_motifs_from_attributed_agents_arel
    @available_motifs_from_attributed_agents_arel ||= 
      # Pour pouvoir utilser le `or` de la méthode `available_motifs_arels` il faut avoir des
      # requête avec les mêmes jointures, donc cette requête supplémentaire est nécessaire
      Motif.where(
        id: (available_collective_motifs_from_attributed_agents_arel +
            available_individual_motifs_from_attributed_agents_arel).flat_map(&:ids)
      )
  end

  def available_motifs_base
    @available_motifs_base ||= Motif.where(id: individual_and_collectifs_motifs_ids).joins(:organisation)
  end

  def individual_motifs
    @individual_motifs ||= Motif.active.where.not(bookable_by: :agents).individuel.joins(:motifs_plage_ouvertures)
      .joins(organisation: :territory).where(territories: { departement_number: @departement }).distinct
  end

  def collective_motifs
    @collective_motifs ||= Motif.active.where.not(bookable_by: :agents).collectif
      .joins(organisation: :territory).where(territories: { departement_number: @departement })
      .joins(:rdvs).merge(Rdv.collectif_and_available_for_reservation).distinct
  end

  def individual_and_collectifs_motifs_ids
    @individual_and_collectifs_motifs_ids ||= individual_motifs.select(:id).ids + collective_motifs.select(:id).ids
  end

  def available_individual_motifs_from_attributed_agents_arel
    @available_individual_motifs_from_attributed_agents_arel ||= attributed_agents_by_organisation
      .map do |organisation, agents|
        agents.map { available_individual_motifs_from_attributed_agent_arel(_1, organisation) }
      end.flatten(1)
  end

  def available_individual_motifs_from_attributed_agent_arel(agent, organisation)
    individual_motifs.sectorisation_level_agent
      .joins(:plage_ouvertures)
      .where(
        organisation_id: organisation.id,
        plage_ouvertures: { agent_id: agent.id }
      )
  end

  def available_collective_motifs_from_attributed_agents_arel
    @available_collective_motifs_from_attributed_agents_arel ||= attributed_agents_by_organisation
      .map do |organisation, agents|
        agents.map { available_collective_motifs_from_attributed_agent_arel(_1, organisation) }
      end.flatten(1)
  end

  def available_collective_motifs_from_attributed_agent_arel(agent, organisation)
    collective_motifs.sectorisation_level_agent
      .where(organisation_id: organisation.id)
      .joins(rdvs: :agents)
      .where(rdvs: { agents: { id: agent.id } })
  end
end

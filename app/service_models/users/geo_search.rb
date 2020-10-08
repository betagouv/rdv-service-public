class Users::GeoSearch
  def initialize(departement:, city_code: nil)
    @departement = departement
    @city_code = city_code
  end

  def departement_sectorisation_enabled?
    ENV["SECTORISATION_ENABLED_DEPARTMENT_LIST"]&.split&.include?(@departement)
  end

  def attributed_organisations
    @attributed_organisations ||= \
      if departement_sectorisation_enabled?
        Organisation.attributed_to_sectors(matching_sectors)
      else
        Organisation.where(departement: @departement)
      end
  end

  def attributed_agents_by_organisation
    return {} unless departement_sectorisation_enabled?

    @attributed_agents_by_organisation ||= matching_sectors
      .map { |sector| sector.attributions.level_agent.includes(:agent).to_a }
      .flatten
      .group_by(&:organisation)
      .transform_values { |attributions| attributions.map(&:agent) }
  end

  def matching_zones
    return nil if !departement_sectorisation_enabled? || @city_code.nil?

    @matching_zones ||= Zone.includes(:sector).where(city_code: @city_code)
  end

  def matching_sectors
    return nil unless departement_sectorisation_enabled?

    @matching_sectors ||= Sector.where(id: matching_zones.pluck(:sector_id))
  end

  def available_services
    @available_services ||= Service.where(id: available_motifs.pluck(:service_id).uniq)
  end

  def available_motifs
    @available_motifs ||= available_motifs_arels.reduce(:or)
  end

  def empty_attributions?
    attributed_organisations.empty? && attributed_agents_by_organisation.empty?
  end

  private

  def available_motifs_arels
    [available_motifs_from_attributed_organisations_arel] +
      available_motifs_from_attributed_agents_arels
  end

  def available_motifs_from_attributed_organisations_arel
    @available_motifs_from_attributed_organisations_arel ||= available_motifs_base
      .where(organisations: { id: attributed_organisations.pluck(:id) })
  end

  def available_motifs_from_attributed_agents_arels
    @available_motifs_from_attributed_agents_arels ||= attributed_agents_by_organisation
      .map do |organisation, agents|
        agents.map { available_motifs_from_attributed_agent_arel(_1, organisation) }
      end
      .flatten(1)
  end

  def available_motifs_from_attributed_agent_arel(agent, organisation)
    available_motifs_base.where(
      organisations: { id: organisation.id },
      plage_ouvertures: { agent_id: agent.id }
    )
  end

  def available_motifs_base
    Motif.reservable_online.active.joins(:organisation, :plage_ouvertures)
  end
end

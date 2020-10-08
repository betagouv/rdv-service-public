class FooService < BaseService # TODO: find name
  def initialize(sectorisation_infos)
    @sectorisation_infos = sectorisation_infos
  end

  def perform
    OpenStruct.new({ motifs: motifs, services: services })
  end

  private

  def services
    @services ||= Service.where(id: motifs.pluck(:service_id).uniq)
  end

  def motifs
    @motifs ||= (motifs_from_attributed_agents_arels || [])
      .reduce(motifs_from_attributed_organisations_arel) { _1.or(_2) }
  end

  def motifs_from_attributed_organisations_arel
    @motifs_from_attributed_organisations_arel ||= motifs_base
      .where(organisations: { id: @sectorisation_infos.attributed_organisations.pluck(:id) })
  end

  def motifs_from_attributed_agents_arels
    @motifs_from_attributed_agents_arels ||= @sectorisation_infos
      .attributed_agents_by_organisation
      &.map do |organisation, agents|
        agents.map { motifs_from_attributed_agent(_1, organisation) }
      end
      &.flatten(1)
  end

  def motifs_from_attributed_agent(agent, organisation)
    motifs_base.where(
      organisations: { id: organisation.id },
      plage_ouvertures: { agent_id: agent.id }
    )
  end

  def motifs_base
    Motif.reservable_online.active.joins(:organisation, :plage_ouvertures)
  end
end

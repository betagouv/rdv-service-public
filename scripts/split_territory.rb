class SplitTerritory
  def initialize(territory_id, main_territory_admin_id, new_territory_name)
    @territory_id = territory_id
    @main_territory_admin_id = main_territory_admin_id
    @new_territory_name = new_territory_name
  end

  def split!
    Territory.transaction do
      puts "Création du nouveau territoire"
      @new_territory = old_territory.dup
      @new_territory.name = @new_territory_name
      @new_territory.save!

      move_organisations

      move_or_duplicate_agent_territorial_roles
      move_or_duplicate_agent_territorial_access_rights

      move_or_duplicate_motif_categories_territories
      move_or_duplicate_territory_services

      move_sectors
      move_teams
      raise "rolling back transaction for dry run"
    end
  end

  private

  attr_reader :new_territory, :main_territory_admin_id

  def move_organisations
    puts "Déplacement des organisations :"
    organisations_to_change = old_territory.organisations.where.not(
      id: AgentRole.where(agent_id: main_territory_admin_id).select(:organisation_id)
    )

    organisations_to_change.each do |organisation|
      puts organisation.name
      organisation.update(territory_id: new_territory.id)
    end
  end

  def move_or_duplicate_agent_territorial_access_rights
    AgentTerritorialAccessRight.where(territory_id: @territory_id).find_each do |agent_territorial_access_right|
      territory_ids_from_agent_organisations = agent_territorial_access_right.agent.organisations.pluck(:territory_id)

      agent_in_new_territory = territory_ids_from_agent_organisations.include?(new_territory.id)
      agent_in_old_territory = territory_ids_from_agent_organisations.include?(old_territory.id)

      if agent_in_new_territory
        if agent_in_old_territory
          puts "Création de nouveaux AgentTerritorialAccessRights pour #{agent_territorial_access_right.agent.email}"
          new_access_right = agent_territorial_access_right.dup
          new_access_right.update!(territory_id: new_territory.id)
        else
          puts "Changement de territoire pour #{agent_territorial_access_right.agent.email}"
          agent_territorial_access_right.update!(territory: new_territory)
        end
      end
    end
  end

  def move_or_duplicate_agent_territorial_roles
    puts "Déplacement des Admins de territoires"
    AgentTerritorialRole.where(territory: old_territory).each do |agent_territorial_role|
      agent = agent_territorial_role.agent
      territory_ids_from_agent_organisations = agent.organisations.pluck(:territory_id)

      agent_in_new_territory = territory_ids_from_agent_organisations.include?(new_territory.id)
      agent_in_old_territory = territory_ids_from_agent_organisations.include?(old_territory.id)

      if agent_in_new_territory
        if agent_in_old_territory
          puts "Création de nouveaux AgentTerritorialRole pour #{agent.email}"
          AgentTerritorialRole.create!(territory: new_territory, agent: agent)
        else
          puts "Changement de territoire pour l'admin de territoire #{agent.email}"
          agent_territorial_role.update!(territory: new_territory)
        end
      end
    end
  end

  def move_or_duplicate_motif_categories_territories
    puts "Déplacement ou création des catégories de motifs"
    MotifCategoriesTerritory.where(territory: old_territory).each do |motif_categories_territory|
      present_in_old_territory = motif_category_present_in_territory?(motif_categories_territory.motif_category_id, old_territory)
      present_in_new_territory = motif_category_present_in_territory?(motif_categories_territory.motif_category_id, new_territory)

      if present_in_new_territory
        if present_in_old_territory
          MotifCategoriesTerritory.create!(territory: new_territory, motif_category: motif_categories_territory.motif_category)
        else
          motif_categories_territory.update!(territory: new_territory)
        end
      end
    end
  end

  def motif_category_present_in_territory?(motif_category_id, territory)
    Motif.joins(:organisation).where(
      motif_category_id: motif_category_id
    ).where(
      organisations: { territory_id: territory.id }
    ).any?
  end

  def move_or_duplicate_territory_services
    TerritoryService.where(territory: old_territory).each do |territory_service|
      present_in_old_territory = service_present_in?(territory_service.service_id, old_territory)
      present_in_new_territory = service_present_in?(territory_service.service_id, new_territory)

      if present_in_new_territory
        if present_in_old_territory
          TerritoryService.create!(territory: new_territory, service_id: territory_service.service_id)
        else
          territory_service.update!(territory: new_territory)
        end
      end
    end
  end

  def service_present_in?(service_id, territory)
    Agent.joins(:services).where(services: { id: service_id })
      .joins(:organisations).where(organisations: { territory_id: territory.id }).any?
  end

  def move_sectors
    old_territory.sectors.each do |sector|
      territory_ids = sector.organisations.pluck(:territory_id).uniq + sectors.attributions.joins(agent: :organisations).pluck("organisations.territory_id").uniq

      if territory_ids.count > 1
        raise "Shared sectors can't be handled"
      end

      if territory_ids == [new_territory.id]
        sector.update!(territory: new_territory)
      end
    end
  end

  def move_teams
    if old_territory.teams.any? # false pour la plupart des territoires, dont la Drome
      raise "This script doesn't have the logic to move teams yet!"
    end
  end

  def old_territory
    @old_territory ||= Territory.find(@territory_id)
  end
end

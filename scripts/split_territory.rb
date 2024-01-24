class SplitTerritory
  def initialize(territory_id, main_territory_admin_id)
    @territory_id = territory_id
    @main_territory_admin_id = main_territory_admin_id
  end

  def split!
    territory_attributes = old_territory.attributes
    Territory.transaction do
      puts "Création du nouveau territoire"
      @new_territory = Territory.create(territory_attributes)

      move_organisations
      move_or_duplicate_agent_territorial_roles
      move_territorial_access_rights
    end
  end

  private

  attr_reader :new_territory

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
    AgentTerritorialAccessRights.where(territory_id: @territory_id).find_each do |_agent_territorial_access_right|
      territory_ids_from_agent_organisations = agent_territorial_access_right.agent.organisations.pluck(:territory_id)

      agent_in_new_territory = territory_ids_from_agent_organisations.include?(new_territory.id)
      agent_in_old_territory = territory_ids_from_agent_organisations.include?(old_territory.id)

      if agent_in_new_territory
        if agent_in_old_territory
          puts "Création de nouveaux AgentTerritorialAccessRights pour #{agent_territorial_access_right.agent.email}"
          AgentTerritorialAccessRights.create!(agent_territorial_role.attributes.merge(territory_id: new_territory.id))
        else
          puts "Changement de territoire pour #{agent_territorial_access_right.agent.email}"
          agent_territorial_role.update!(territory: new_territory)
        end
      end
    end
  end

  def move_territorial_access_roles
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

  def old_territory
    @old_territory ||= Territory.find(@territory_id)
  end
end

# Ce script se base sur le fait que les admin de territoires sont aussi admin d'organisation de toutes leurs orgas
# Example:
# load "scripts/split_territory.rb"; SplitTerritory.new(4, 530, "Drôme Insertion", dry_run: true).split!

class MotifCategoriesTerritory < ApplicationRecord
  belongs_to :motif_category
  belongs_to :territory
end

class SplitTerritory
  def initialize(old_territory_id, main_territory_admin_id, new_territory_name, dry_run: true)
    @old_territory_id = old_territory_id
    @old_territory ||= Territory.find(@old_territory_id)
    @main_territory_admin_id = main_territory_admin_id
    @main_territory_admin = Agent.find(@main_territory_admin_id)
    @new_territory_name = new_territory_name
    @dry_run = dry_run
  end

  def split!
    Territory.transaction do
      puts "# Création du nouveau territoire #{@new_territory_name}"
      @new_territory = @old_territory.dup
      @new_territory.name = @new_territory_name
      @new_territory.save!

      move_organisations

      move_or_duplicate_agent_territorial_roles
      move_or_duplicate_agent_territorial_access_rights

      move_or_duplicate_motif_categories_territories
      move_or_duplicate_territory_services

      move_sectors
      move_teams
      if @dry_run
        raise "rolling back transaction for dry run"
      end
    end
  end

  private

  def move_organisations
    puts "\n\n## Déplacement des organisations suivantes dans le nouveau territoire :"
    organisations_to_change = @old_territory.organisations - @main_territory_admin.organisations

    organisations_to_change.sort_by(&:name).each do |organisation|
      puts "- #{organisation.name}"
      organisation.update_columns(territory_id: @new_territory.id) # rubocop:disable Rails/SkipsModelValidations
    end

    puts "\nLes organisations suivantes restent dans le territoire actuel"
    @old_territory.organisations.reload.ordered_by_name.each do |org|
      puts "- #{org.name}"
    end
  end

  def move_or_duplicate_agent_territorial_access_rights
    puts "\n\n## Déplacement des Agents\n"
    AgentTerritorialAccessRight.where(territory_id: @old_territory_id).find_each do |agent_territorial_access_right|
      agent = agent_territorial_access_right.agent
      territory_ids_from_agent_organisations = agent.organisations.pluck(:territory_id)

      agent_in_new_territory = territory_ids_from_agent_organisations.include?(@new_territory.id)
      agent_in_old_territory = territory_ids_from_agent_organisations.include?(@old_territory.id)

      if agent_in_new_territory
        if agent_in_old_territory
          puts "Création de nouveaux AgentTerritorialAccessRights pour #{agent.email}"
          new_access_right = agent_territorial_access_right.dup
          new_access_right.update!(territory_id: @new_territory.id)
        else
          puts "Changement de territoire pour #{agent.email}"
          agent_territorial_access_right.update!(territory: @new_territory)
        end
      end
    end

    puts "#{AgentTerritorialAccessRight.where(territory: @new_territory).count} agents dans le nouveau territoire"
  end

  def move_or_duplicate_agent_territorial_roles
    puts "\n\n## Déplacement des Admins de territoires"
    AgentTerritorialRole.where(territory: @old_territory).each do |agent_territorial_role|
      agent = agent_territorial_role.agent
      territory_ids_from_agent_organisations = agent.organisations.pluck(:territory_id)

      agent_in_new_territory = territory_ids_from_agent_organisations.include?(@new_territory.id)
      agent_in_old_territory = territory_ids_from_agent_organisations.include?(@old_territory.id)

      if agent_in_new_territory
        if agent_in_old_territory
          puts "Création de nouveaux AgentTerritorialRole pour #{agent.email}"
          AgentTerritorialRole.create!(territory: @new_territory, agent: agent)
        else
          puts "Changement de territoire pour l'admin de territoire #{agent.email}"
          agent_territorial_role.update!(territory: @new_territory)
        end
      end
    end
  end

  def move_or_duplicate_motif_categories_territories
    puts "\n\n## Déplacement ou création des catégories de motifs\n"
    MotifCategoriesTerritory.where(territory: @old_territory).each do |motif_categories_territory|
      present_in_old_territory = motif_category_used_in_territory_motifs?(motif_categories_territory.motif_category_id, @old_territory)
      present_in_new_territory = motif_category_used_in_territory_motifs?(motif_categories_territory.motif_category_id, @new_territory)

      next unless present_in_new_territory

      if present_in_old_territory
        puts "Ajout de la catégorie de motifs #{motif_categories_territory.motif_category.name} au nouveau territoire"
        MotifCategoriesTerritory.create!(territory: @new_territory, motif_category: motif_categories_territory.motif_category)
      else
        puts "Déplacement de la catégorie de motifs #{motif_categories_territory.motif_category.name} dans le nouveau territoire"
        # Cette table n'ayant pas d'id, on est obligés de passer par un update_all plutôt qu'un simple update sur le record
        MotifCategoriesTerritory.where(territory_id: @old_territory.id, motif_category_id: motif_categories_territory.motif_category_id).update_all(territory_id: @new_territory.id) # rubocop:disable Rails/SkipsModelValidations
      end
    end
  end

  def motif_category_used_in_territory_motifs?(motif_category_id, territory)
    Motif.joins(:organisation).where(
      motif_category_id: motif_category_id
    ).where(
      organisations: { territory_id: territory.id }
    ).any?
  end

  def move_or_duplicate_territory_services
    TerritoryService.where(territory: @old_territory).each do |territory_service|
      present_in_old_territory = service_present_in?(territory_service.service_id, @old_territory)
      present_in_new_territory = service_present_in?(territory_service.service_id, @new_territory)

      if present_in_new_territory
        if present_in_old_territory
          TerritoryService.create!(territory: @new_territory, service_id: territory_service.service_id)
        else
          territory_service.update!(territory: @new_territory)
        end
      end
    end
  end

  def service_present_in?(service_id, territory)
    Agent.joins(:services).where(services: { id: service_id })
      .joins(:organisations).where(organisations: { territory_id: territory.id }).any?
  end

  def move_sectors
    puts "\n\n## Déplacement des secteurs"
    @old_territory.sectors.each do |sector|
      territory_ids_from_organisation_attributions = sector.organisations.pluck(:territory_id).uniq
      territory_ids_from_agent_attributions = sector.attributions.joins(agent: :organisations).pluck("organisations.territory_id").uniq

      territory_ids = (territory_ids_from_organisation_attributions + territory_ids_from_agent_attributions).uniq

      if territory_ids.count > 1
        raise "Shared sector #{sector.id} can't be handled"
      end

      if territory_ids == [@new_territory.id]
        puts "Déplacement du secteur #{sector.id} dans le nouveau territoire"
        sector.update!(territory: @new_territory)
      end
    end
  end

  def move_teams
    puts "\n\n## Déplacement des équipes"
    @old_territory.teams.each do |team|
      territory_ids = team.agents.map(&:agent_territorial_access_rights).flatten.map(&:territory_id).uniq

      if territory_ids.count > 1
        raise "L'équipe #{team.id} est partagée entre les deux territoires"
      elsif territory_ids == [@new_territory.id]
        puts "Déplacement de l'équipe #{team.id} dans le nouveau territoire"
        team.update!(territory: @new_territory)
      end
    end
  end
end

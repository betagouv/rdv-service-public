class MoveOrganisationToOtherTerritoryService < BaseService
  attr_accessor :counters

  def initialize(origin_organisation:, target_territory:)
    @origin_organisation = origin_organisation
    @territory_origin = origin_organisation.territory
    @territory_target = target_territory
    @counters = Hash.new(0)
  end

  def call
    check_preconditions
    move_organisation
  end

  private

  def check_preconditions
    raise "Organisation not found" unless @origin_organisation
    raise "Territory not found" unless @territory_target
  end

  def move_organisation
    Rails.logger.info("=== MIGRATION D'ORGANISATION VERS UN AUTRE TERRITOIRE ===")
    Rails.logger.info("Organisation: #{@origin_organisation.name} (ID: #{@origin_organisation.id})")
    Rails.logger.info("Territoire source: #{@territory_origin.name} (ID: #{@territory_origin.id})")
    Rails.logger.info("Territoire cible: #{@territory_target.name} (ID: #{@territory_target.id})")

    ActiveRecord::Base.transaction do
      Rails.logger.info("🔄 Début de la migration (dans une transaction)…")

      move_annotations
      move_motif_categories
      move_services
      move_teams
      move_access_rights
      move_territorial_roles
      delete_sector_attributions
      move_organisation_record
      suggest_cleanup_origin_territory

      Rails.logger.info("✅ MIGRATION TERMINÉE AVEC SUCCÈS!")
    end
  end

  def move_annotations
    Rails.logger.info("🔄 Migration des annotations…")
    @origin_organisation.users.includes(:annotations).each do |user|
      source_annotation = user.annotations.find_by(territory: @territory_origin)
      next unless source_annotation

      target_annotation = user.annotations.find_by(territory: @territory_target)
      if target_annotation
        Rails.logger.info("  ⚠️  Conflit d'annotation pour l'utilisateur #{user.id} - fusion du contenu")
        merged_content = [target_annotation.content, source_annotation.content].compact.join("\n---\n")
        target_annotation.update!(content: merged_content)
        source_annotation.destroy!
        counters[:annotation_conflicts] += 1
      else
        source_annotation.update!(territory: @territory_target)
        counters[:annotation_moves] += 1
      end
    end
    Rails.logger.info("  ✅ #{counters[:annotation_moves]} annotations déplacées, #{counters[:annotation_conflicts]} fusions effectuées")
  end

  def move_motif_categories
    Rails.logger.info("🔄  Ajout des catégories de motifs manquantes…")
    @territory_origin.motif_categories.each do |motif_category|
      next if @territory_target.motif_categories.include?(motif_category)

      @territory_target.motif_categories << motif_category
      Rails.logger.info("  ➕ Catégorie de motifs '#{motif_category.name}' ajoutée au territoire cible")
      counters[:motif_category_associations] += 1
    end
    Rails.logger.info("  ✅ #{counters[:motif_category_associations]} catégories de motifs ajoutées au territoire cible")
  end

  def move_services
    Rails.logger.info("🔄 Ajout des services manquants…")
    @territory_origin.services.each do |service|
      next if @territory_target.services.include?(service)

      TerritoryService.create!(territory: @territory_target, service: service)
      Rails.logger.info("  ➕ Service '#{service.name}' ajouté au territoire cible")
      counters[:service_associations] += 1
    end
    Rails.logger.info("  ✅ #{counters[:service_associations]} services ajoutés au territoire cible")
  end

  def move_teams
    Rails.logger.info("🔄 Migration des équipes…")
    @territory_origin.teams.includes(:agents).each do |team_origin|
      agents = team_origin.agents & @origin_organisation.agents

      team_target_existing = @territory_target.teams.find_by(name: team_origin.name)
      if team_target_existing
        Rails.logger.info("  ⚠️  Équipe '#{team_origin.name}' existe déjà dans le territoire cible - fusion des agents")
        agents.each do |agent|
          if team_target_existing.agents.include?(agent)
            Rails.logger.info("    - Agent #{agent.id} déjà dans l'équipe cible")
          else
            team_target_existing.agents << agent
            Rails.logger.info("    - Agent #{agent.id} ajouté à l'équipe existante")
          end
        end
        team_origin.destroy!
        counters[:team_conflicts] += 1
      else
        team_origin.update!(territory: @territory_target)
        Rails.logger.info("  ➕ Équipe '#{team_origin.name}' déplacée dans le territoire cible")
        counters[:team_moves] += 1
      end
    end
    Rails.logger.info("  ✅ #{counters[:team_moves]} équipes créées, #{counters[:team_conflicts]} fusions effectuées")
  end

  def move_access_rights
    Rails.logger.info("🔄 Migration des droits d'accès territoriaux…")
    AgentTerritorialAccessRight.where(territory: @territory_origin).each do |access_right_origin|
      agent = access_right_origin.agent
      access_right_target = agent.agent_territorial_access_rights.find_by(territory: @territory_target)
      if access_right_target
        Rails.logger.info("  ⚠️  Droits d'accès existants pour l'agent #{agent.id} - fusion des permissions")
        access_right_target.update!(
          allow_to_manage_teams: access_right_target.allow_to_manage_teams || access_right_origin.allow_to_manage_teams,
          allow_to_manage_access_rights: access_right_target.allow_to_manage_access_rights || access_right_origin.allow_to_manage_access_rights,
          allow_to_invite_agents: access_right_target.allow_to_invite_agents || access_right_origin.allow_to_invite_agents
        )
        access_right_origin.destroy!
        counters[:access_rights_merges] += 1
      else
        access_right_origin.update!(territory: @territory_target)
        counters[:access_rights_moves] += 1
      end
    end
    Rails.logger.info("  ✅ #{counters[:access_rights_moves]} droits déplacés, #{counters[:access_rights_merges]} fusions effectuées")
  end

  def move_territorial_roles
    Rails.logger.info("🔄 Migration des rôles territoriaux d'agents…")
    AgentTerritorialRole.where(territory: @territory_origin).each do |role_origin|
      agent = role_origin.agent
      if agent.territorial_roles.exists?(territory: @territory_target)
        AgentTerritorialRole.where(id: role_origin.id).delete_all # skip validations
        Rails.logger.info("  ℹ️  Agent #{agent.id} a déjà un rôle territorial dans le territoire cible")
      else
        role_origin.update!(territory: @territory_target)
        Rails.logger.info("  ➕ Rôle territorial créé pour l'agent #{agent.id}")
        counters[:territorial_roles_created] += 1
      end
    end
    Rails.logger.info("  ✅ #{counters[:territorial_roles_created]} nouveaux rôles territoriaux créés")
  end

  def delete_sector_attributions
    Rails.logger.info("🔄  Vérification des secteurs…")
    @origin_organisation.sector_attributions.includes(:sector).each do |attribution|
      next unless attribution.sector.territory != @territory_target

      Rails.logger.info("  ⚠️  Suppression de l'attribution au secteur '#{attribution.sector.name}' (territoire différent)")
      attribution.destroy!
      counters[:removed_attributions] += 1
    end
    Rails.logger.info("  ✅ #{counters[:removed_attributions]} attributions de secteurs supprimées")
  end

  def move_organisation_record
    Rails.logger.info("🔄 Déplacement de l'organisation…")
    @origin_organisation.update!(territory: @territory_target)
    Rails.logger.info("  ✅ Organisation '#{@origin_organisation.name}' déplacée vers le territoire '#{@territory_target.name}'")
  end

  def suggest_cleanup_origin_territory
    return if @territory_origin.organisations.any?

    Rails.logger.info("🧹 Le territoire '#{@territory_origin.name}' n'a plus d'organisations.")
    Rails.logger.info("   Vous devriez envisager de le supprimer ou de transférer ses ressources restantes.")
    remaining_teams = @territory_origin.teams.count
    remaining_sectors = @territory_origin.sectors.count
    remaining_roles = @territory_origin.roles.count
    Rails.logger.info("   Ressources restantes: #{remaining_teams} équipes, #{remaining_sectors} secteurs, #{remaining_roles} rôles")
  end
end

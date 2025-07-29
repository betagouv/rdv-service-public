class MoveOrganisationToOtherTerritoryService < BaseService
  attr_accessor :counters

  def initialize(origin_organisation:, target_territory:)
    @origin_organisation = origin_organisation
    @territory_origin = origin_organisation.territory
    @territory_target = target_territory
    @counters = Hash.new(0)
  end

  def call
    Rails.logger.info("=== MIGRATION D'ORGANISATION VERS UN AUTRE TERRITOIRE ===")
    Rails.logger.info("Organisation: #{@origin_organisation.name} (ID: #{@origin_organisation.id})")
    Rails.logger.info("Territoire source: #{@territory_origin.name} (ID: #{@territory_origin.id})")
    Rails.logger.info("Territoire cible: #{@territory_target.name} (ID: #{@territory_target.id})")

    ActiveRecord::Base.transaction do
      Rails.logger.info("🔄 Début de la migration (dans une transaction)…")

      copy_annotations
      copy_motif_categories
      copy_services
      copy_teams
      copy_access_rights
      copy_territorial_roles
      move_organisation_record
      suggest_cleanup_origin_territory

      Rails.logger.info("✅ MIGRATION TERMINÉE AVEC SUCCÈS!")
    end
  end

  private

  def copy_annotations
    Rails.logger.info("🔄 Migration des annotations…")
    Annotation.where(user_id: @origin_organisation.user_ids, territory: @territory_origin).each do |source_annotation|
      user = source_annotation.user
      target_annotation = user.annotations.find_by(territory: @territory_target)
      if target_annotation
        Rails.logger.info("  ⚠️  Conflit d'annotation pour l'utilisateur #{user.id} - fusion du contenu")
        merged_content = [target_annotation.content, source_annotation.content].compact.join("\n---\n")
        target_annotation.update!(content: merged_content)
        counters[:annotation_conflicts] += 1
      else
        new_annotation = source_annotation.dup
        new_annotation.territory = @territory_target
        new_annotation.save!
        counters[:annotation_copies] += 1
      end
    end
    Rails.logger.info("  ✅ #{counters[:annotation_copies]} annotations copiées, #{counters[:annotation_conflicts]} fusions effectuées")
  end

  def copy_motif_categories
    Rails.logger.info("🔄  Ajout des catégories de motifs manquantes…")
    @territory_origin.motif_categories.each do |motif_category|
      next if @territory_target.motif_categories.include?(motif_category)

      @territory_target.motif_categories << motif_category
      Rails.logger.info("  ➕ Catégorie de motifs '#{motif_category.name}' ajoutée au territoire cible")
      counters[:motif_category_associations] += 1
    end
    Rails.logger.info("  ✅ #{counters[:motif_category_associations]} catégories de motifs ajoutées au territoire cible")
  end

  def copy_services
    Rails.logger.info("🔄 Ajout des services manquants…")
    @territory_origin.services.each do |service|
      next if @territory_target.services.include?(service)

      TerritoryService.create!(territory: @territory_target, service: service)
      Rails.logger.info("  ➕ Service '#{service.name}' ajouté au territoire cible")
      counters[:service_associations] += 1
    end
    Rails.logger.info("  ✅ #{counters[:service_associations]} services ajoutés au territoire cible")
  end

  def copy_teams
    Rails.logger.info("🔄 Copie des équipes…")
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
        counters[:team_conflicts] += 1
      else
        team_target_new = team_origin.dup
        team_target_new.territory = @territory_target
        team_target_new.agents = agents
        team_target_new.save!
        Rails.logger.info("  ➕ Équipe '#{team_origin.name}' copiée dans le territoire cible")
        counters[:team_copies] += 1
      end
    end
    Rails.logger.info("  ✅ #{counters[:team_copies]} équipes copiées, #{counters[:team_conflicts]} fusions effectuées")
  end

  def copy_access_rights
    Rails.logger.info("🔄 Copie des droits d'accès territoriaux…")
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
        counters[:access_rights_merges] += 1
      else
        new_access_right = access_right_origin.dup
        new_access_right.territory = @territory_target
        new_access_right.save!
        counters[:access_rights_copies] += 1
      end
    end
    Rails.logger.info("  ✅ #{counters[:access_rights_copies]} droits copiés, #{counters[:access_rights_merges]} fusions effectuées")
  end

  def copy_territorial_roles
    Rails.logger.info("🔄 Copie des rôles territoriaux d'agents…")
    AgentTerritorialRole.where(territory: @territory_origin).each do |role_origin|
      agent = role_origin.agent
      if agent.territorial_roles.exists?(territory: @territory_target)
        Rails.logger.info("  ℹ️  Agent #{agent.id} a déjà un rôle territorial dans le territoire cible")
      else
        new_role = role_origin.dup
        new_role.territory = @territory_target
        new_role.save!
        Rails.logger.info("  ➕ Rôle territorial copié pour l'agent #{agent.id}")
        counters[:territorial_roles_copies] += 1
      end
    end
    Rails.logger.info("  ✅ #{counters[:territorial_roles_copies]} nouveaux rôles territoriaux copiés")
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

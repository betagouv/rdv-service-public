# frozen_string_literal: true

class AddAllowToManageAccessRightsToAgentTerritorialAccessRights < ActiveRecord::Migration[6.1]
  def change
    add_column :agent_territorial_access_rights, :allow_to_manage_access_rights, :boolean, default: false, null: false
    add_column :agent_territorial_access_rights, :allow_to_invite_agents, :boolean, default: false, null: false

    # Tous les agents qui ont été créé depuis la dernière migration n'ont pas
    # été associés à un territoire via la table des droits d'accès
    # Soit presque l'ensemble des conseillers numériques
    # plus quelques autres agents créés entre temps.
    #
    # Ici, on reconstruit ce lien pour les agents qui ne sont pas présent
    # dans la table `AgentTerritorialAccessRights`
    Agent.where.not(id: AgentTerritorialAccessRight.all.pluck(:agent_id)).each do |agent|
      agent.organisations.flat_map(&:territory).each do |territory|
        AgentTerritorialAccessRight.create!(agent: agent, territory: territory)
      end
    end

    # Nous avons besoin de retrouver l'agent et le territoire
    # pour lequel donner les droits d'accès.
    # Difficile de passer par un `update_all`
    #
    # Les admin d'organisation ont automatiquement
    # le droit d'inviter des agents.
    # Ils seront limité aux organisations auxquelles
    # ils accèdent
    AgentRole.where(level: "admin").each do |agent_role|
      AgentTerritorialAccessRight.where(
        agent: agent_role.agent,
        territory: agent_role.organisation.territory
      ).update(allow_to_invite_agents: true)
    end

    # Nous avons besoin de retrouver l'agent et le territoire
    # pour lequel donner les droits d'accès.
    # Difficile de passer par un `update_all`
    #
    # Les admin de territoire ont automatiquement le droit de
    # - gérer les droits d'accès
    # - d'inviter des agents
    AgentTerritorialRole.all.each do |territorial_role|
      AgentTerritorialAccessRight.where(
        agent: territorial_role.agent,
        territory: territorial_role.territory
      ).update(
        allow_to_invite_agents: true,
        allow_to_manage_access_rights: true
      )
    end
  end
end

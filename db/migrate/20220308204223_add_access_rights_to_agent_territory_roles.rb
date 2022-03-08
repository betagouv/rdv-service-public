# frozen_string_literal: true

class AddAccessRightsToAgentTerritoryRoles < ActiveRecord::Migration[6.1]
  def change
    add_column :agent_territorial_roles, :allow_to_invite_agents, :boolean, default: false, nil: false
    add_column :agent_territorial_roles, :allow_to_agents_access_right, :boolean, default: false, nil: false
    add_column :agent_territorial_roles, :allow_to_manage_sectorization, :boolean, default: false, nil: false
    add_column :agent_territorial_roles, :allow_to_manage_organisation, :boolean, default: false, nil: false
    add_column :agent_territorial_roles, :allow_to_manage_webhook, :boolean, default: false, nil: false
    add_column :agent_territorial_roles, :allow_to_manage_sms_provider, :boolean, default: false, nil: false
    add_column :agent_territorial_roles, :allow_to_manage_teams, :boolean, default: false, nil: false
    add_column :agent_territorial_roles, :allow_to_change_display_preferences, :boolean, default: false, nil: false
    add_column :agent_territorial_roles, :allow_to_update_entity_informations, :boolean, default: false, nil: false

    AgentTerritorialRole.all.each do |role|
      role.update(
        allow_to_invite_agents: true,
        allow_to_agents_access_right: true,
        allow_to_manage_sectorization: true,
        allow_to_manage_organisation: true,
        allow_to_manage_webhook: true,
        allow_to_manage_sms_provider: true,
        allow_to_manage_teams: true,
        allow_to_change_display_preferences: true,
        allow_to_update_entity_informations: true
      )
    end

    Agent.all.each do |agent|
      agent.update(territories: Territory.where(organisations: agent.organisations))
    end
  end
end

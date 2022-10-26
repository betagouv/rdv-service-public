# frozen_string_literal: true

class AddAllowToDownloadMetricsToAgentTerritorialAccessRights < ActiveRecord::Migration[6.1]
  def up
    add_column :agent_territorial_access_rights, :allow_to_download_metrics, :boolean, default: false, null: false
    AgentTerritorialAccessRight.where(allow_to_manage_teams: true, allow_to_manage_access_rights: true, allow_to_invite_agents: true).update_all(allow_to_download_metrics: true)
  end

  def down
    remove_column :agent_territorial_access_rights, :allow_to_download_metrics, :boolean
  end
end

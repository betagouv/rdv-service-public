class RemoveAgentTerritorialAccessRightsAllowToDownloadMetrics < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      remove_column :agent_territorial_access_rights, :allow_to_download_metrics, :boolean, default: false, null: false
    end
  end
end

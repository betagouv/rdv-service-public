class CreateOutlookConfigs < ActiveRecord::Migration[8.1]
  def up
    create_table :outlook_configs do |t|
      t.references :agent, null: false, foreign_key: true, index: { unique: true }
      t.text :microsoft_graph_token
      t.text :microsoft_graph_refresh_token
      t.boolean :disconnect_in_progress, default: false, null: false

      t.timestamps
    end

    # Les tokens sont chiffrés (`encrypts`) à l'identique dans agents et dans outlook_configs :
    # on copie donc directement le texte chiffré, en SQL, sans passer par les modèles.
    safety_assured do
      execute <<~SQL.squish
        INSERT INTO outlook_configs (agent_id, microsoft_graph_token, microsoft_graph_refresh_token, disconnect_in_progress, created_at, updated_at)
        SELECT id, microsoft_graph_token, refresh_microsoft_graph_token, outlook_disconnect_in_progress, NOW(), NOW()
        FROM agents
        WHERE microsoft_graph_token IS NOT NULL OR outlook_disconnect_in_progress
      SQL
    end
  end

  def down
    safety_assured do
      execute <<~SQL.squish
        UPDATE agents
        SET microsoft_graph_token = outlook_configs.microsoft_graph_token,
            refresh_microsoft_graph_token = outlook_configs.microsoft_graph_refresh_token,
            outlook_disconnect_in_progress = outlook_configs.disconnect_in_progress
        FROM outlook_configs
        WHERE outlook_configs.agent_id = agents.id
      SQL
    end

    drop_table :outlook_configs
  end
end

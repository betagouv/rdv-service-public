class AddAgentPlages < ActiveRecord::Migration[7.2]
  def up
    create_table :agent_plages do |t|
      t.references :agent, foreign_key: true, index: true, null: false
      t.references :plage_ouverture, foreign_key: true, index: true, null: false

      t.datetime :created_at, null: false
    end

    PlageOuverture.find_each do |plage|
      AgentPlage.create!(agent_id: plage.agent_id, plage_ouverture_id: plage.id, created_at: plage.created_at)
    end

    safety_assured do
      remove_column :plage_ouvertures, :agent_id
    end
  end

  def down
    add_reference :plage_ouvertures, :agent, foreign_key: true, index: true

    AgentPlage.find_each do |agent_plage|
      agent_plage.plage_ouverture.update_columns(agent_id: agent_plage.agent_id)
    end

    safety_assured do
      drop_table :agent_plages
    end
  end
end

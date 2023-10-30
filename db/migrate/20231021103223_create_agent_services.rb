class CreateAgentServices < ActiveRecord::Migration[7.0]
  def up
    create_table :agent_services do |t|
      t.references :agent, foreign_key: true, index: true
      t.references :service, foreign_key: true, index: true

      t.datetime :created_at, null: false
    end

    agent_services_hashes = Agent.pluck(:id, :service_id, :created_at).map do |agent_id, service_id, created_at|
      { agent_id: agent_id, service_id: service_id, created_at: created_at }
    end
    AgentService.insert_all!(agent_services_hashes)

    remove_column :agents, :service_id
  end

  def down
    add_reference :agents, :service, foreign_key: true, index: true

    agents_to_services = AgentService.distinct(:agent_id).pluck(:agent_id, :service_id).map do |agent_id, service_id|
      { id: agent_id, service_id: service_id }
    end
    Agent.upsert_all(agents_to_services)

    change_column_null :agents, :service_id, false

    drop_table :agent_services
  end
end

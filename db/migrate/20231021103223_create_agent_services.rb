class CreateAgentServices < ActiveRecord::Migration[7.0]
  def change
    create_table :agent_services do |t|
      t.references :agent, foreign_key: true, index: true
      t.references :service, foreign_key: true, index: true

      t.datetime :created_at, null: false
    end
  end
end

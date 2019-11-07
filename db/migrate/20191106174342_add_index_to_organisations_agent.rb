class AddIndexToOrganisationsAgent < ActiveRecord::Migration[6.0]
  def change
    ActiveRecord::Base.connection.execute("DELETE FROM agents_organisations WHERE (organisation_id, agent_id) IN (SELECT organisation_id, agent_id FROM agents_organisations GROUP BY organisation_id, agent_id HAVING COUNT(*) > 1)")
    add_index :agents_organisations, [:organisation_id, :agent_id], unique: true
  end
end

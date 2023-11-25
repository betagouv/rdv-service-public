class AddUniqueIndexOnAgentTerritorialRoles < ActiveRecord::Migration[7.0]
  def change
    reversible do |direction|
      direction.up do
        sql_query = <<~SQL.squish
          SELECT COUNT(*) as counter, agent_id, territory_id
          FROM agent_territorial_roles
          GROUP BY agent_id, territory_id
          HAVING COUNT(*) > 1;
        SQL
        agents_with_multiple_configs = ActiveRecord::Base.connection.execute(sql_query).to_a

        agents_with_multiple_configs.each do |result|
          agent = Agent.find(result["agent_id"])
          territory = Territory.find(result["territory_id"])
          counter = result["counter"]
          number_of_duplicates = counter - 1 # we only keep the most recent one

          AgentTerritorialRole
            .where(agent: agent, territory: territory)
            .limit(number_of_duplicates)
            .delete_all
        end
      end
    end

    add_index :agent_territorial_roles, %i[agent_id territory_id], unique: true, name: "index_agent_territorial_roles_unique_agent_territory"

    change_column_null :agent_territorial_roles, :territory_id, false
  end
end

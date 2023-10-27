class AddAgentRoleLevelEnum < ActiveRecord::Migration[7.0]
  def up
    create_enum :access_level, %i[admin basic]
    add_column :agent_roles, :access_level, :access_level, default: :basic, null: false
    add_index :agent_roles, :access_level

    execute(<<-SQL.squish
      UPDATE agent_roles
      SET access_level = level::access_level
    SQL
           )

    remove_column :agent_roles, :level, :string
  end

  def down
    add_column :agent_roles, :level, :string, default: :basic, null: false

    execute(<<-SQL.squish
      UPDATE agent_roles
      SET level = access_level
    SQL
           )

    remove_index :agent_roles, :access_level
    remove_column :agent_roles, :access_level, :string
    drop_enum :access_level
  end
end

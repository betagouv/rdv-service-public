class MakeAgentsUidVirtual < ActiveRecord::Migration[8.0]
  def up
    safety_assured do
      remove_column :agents, :uid
      add_column :agents, :uid, :virtual, type: :string, as: "email", stored: true
      add_index :agents, :uid
    end
  end

  def down
    safety_assured do
      remove_column :agents, :uid
      add_column :agents, :uid, :string

      execute("UPDATE agents SET uid = email")

      add_index :agents, :uid
    end
  end
end

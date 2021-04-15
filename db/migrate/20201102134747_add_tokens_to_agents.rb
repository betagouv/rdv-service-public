class AddTokensToAgents < ActiveRecord::Migration[6.0]
  def change
    add_column :agents, :provider, :string, null: false, default: "email"
    add_column :agents, :uid, :string, null: false, default: ""
    add_column :agents, :tokens, :text
    add_column :agents, :allow_password_change, :boolean, default: false
    Agent.reset_column_information
    Agent.find_each do |agent|
      agent.uid = agent.email
      agent.provider = "email"
      agent.save!
    end
    add_index :agents, %i[uid provider], unique: true
  end

  def down
    remove_columns :agents, :provider, :uid, :tokens, :allow_password_change
  end
end

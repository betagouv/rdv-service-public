class FixAgentsWithMissingUid < ActiveRecord::Migration[6.0]
  def up
    Agent.where(uid: "").each do |agent|
      agent.update_columns(uid: agent.email)
    end
  end
end

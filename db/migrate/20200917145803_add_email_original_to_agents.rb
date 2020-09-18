class AddEmailOriginalToAgents < ActiveRecord::Migration[6.0]
  def change
    add_column :agents, :email_original, :string
  end

  def up
    add_column :agents, :email_original, :string
    Agent.where.not(deleted_at: nil).each do |agent|
      agent.update_columns(email_original: agent.email, email: agent.deleted_email)
      # skip callbacks to avoid mail confirmation
    end
  end

  def down
    Agent.where.not(deleted_at: nil).each do |agent|
      agent.update_columns(email: agent.email_original)
    end
    remove_column :agents, :email_original
  end
end

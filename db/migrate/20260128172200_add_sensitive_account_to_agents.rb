class AddSensitiveAccountToAgents < ActiveRecord::Migration[8.0]
  def up
    add_column :agents, :sensitive_account, :boolean, default: false, null: false

    CronJob::RefreshAgentsSensitiveAccountJob.perform_now
  end

  def down
    remove_column :agents, :sensitive_account
  end
end

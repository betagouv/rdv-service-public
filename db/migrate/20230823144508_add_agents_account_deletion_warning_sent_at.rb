# frozen_string_literal: true

class AddAgentsAccountDeletionWarningSentAt < ActiveRecord::Migration[7.0]
  def change
    add_column :agents, :account_deletion_warning_sent_at, :datetime
    add_index :agents, :account_deletion_warning_sent_at
  end
end

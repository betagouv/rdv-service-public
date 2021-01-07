class SyncDeletedAgentsUidWithEmail < ActiveRecord::Migration[6.0]
  def up
    Agent
      .where.not(deleted_at: nil)
      .where("email != uid")
      .each { _1.update_columns(uid: _1.email) }
  end
end

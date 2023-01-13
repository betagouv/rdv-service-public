class RemoveWaitingFromEnumStatus < ActiveRecord::Migration[7.0]
  def up
    execute(<<-SQL.squish
      UPDATE rdvs
      SET status = 'unknown'
      WHERE status = 'waiting'
    SQL
           )

    execute(<<-SQL.squish
      UPDATE rdvs_users
      SET status = 'unknown'
      WHERE status = 'waiting'
    SQL
           )
    remove_enum_value :rdv_status, "waiting"
  end

  def down
    # We assume migrated "waiting" statuses will not be recovered in case of rollback
    add_enum_value :rdv_status, "waiting"
  end
end

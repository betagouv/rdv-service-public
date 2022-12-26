class AddCancelledAtToRdvsUser < ActiveRecord::Migration[7.0]
  def change
    add_column :rdvs_users, :cancelled_at, :datetime, null: true
    add_timestamps :rdvs_users, null: true

    up_only do
      execute(<<-SQL.squish
        UPDATE rdvs_users SET
        cancelled_at = (SELECT cancelled_at FROM rdvs WHERE rdvs_users.rdv_id = rdvs.id),
        created_at = (SELECT created_at FROM rdvs WHERE rdvs_users.rdv_id = rdvs.id),
        updated_at = (SELECT updated_at FROM rdvs WHERE rdvs_users.rdv_id = rdvs.id)
      SQL
             )
    end

    change_column_null :rdvs_users, :created_at, false
    change_column_null :rdvs_users, :updated_at, false
  end
end

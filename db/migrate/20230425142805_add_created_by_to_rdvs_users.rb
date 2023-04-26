class AddCreatedByToRdvsUsers < ActiveRecord::Migration[7.0]
  def up
    create_enum :created_by, %i[
      agent
      user
      prescripteur
    ]
    add_column :rdvs_users, :created_by, :created_by, null: false, default: :agent

    # migrate created_by :user
    execute(<<-SQL.squish
      UPDATE rdvs_users
      SET created_by = 'user'
      FROM rdvs
      WHERE rdvs_users.rdv_id = rdvs.id
      AND rdvs.created_by = 1
    SQL
           )

    # migrate created_by :prescripteur
    execute(<<-SQL.squish
      UPDATE rdvs_users
      SET created_by = 'prescripteur'
      FROM rdvs
      WHERE rdvs_users.rdv_id = rdvs.id
      AND rdvs.created_by = 3
    SQL
           )

    add_timestamps :rdvs_users, null: true
    execute(<<-SQL.squish
      UPDATE rdvs_users SET
      created_at = (SELECT created_at FROM rdvs WHERE rdvs_users.rdv_id = rdvs.id),
      updated_at = (SELECT updated_at FROM rdvs WHERE rdvs_users.rdv_id = rdvs.id)
    SQL
           )
    change_column_null :rdvs_users, :created_at, false
    change_column_null :rdvs_users, :updated_at, false
  end

  def down
    remove_column :rdvs_users, :created_by, :created_by
    remove_column :rdvs_users, :created_at
    remove_column :rdvs_users, :updated_at
    drop_enum :created_by
  end
end

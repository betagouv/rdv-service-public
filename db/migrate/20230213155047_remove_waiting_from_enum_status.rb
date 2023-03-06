# frozen_string_literal: true

class RemoveWaitingFromEnumStatus < ActiveRecord::Migration[7.0]
  def up
    # Migrate waiting status to unknown
    migrate_waiting_statuses_to_unknown

    # Add temp_status and copy status values to temp_status
    add_temp_status_and_copy_data

    # Remove status and enum
    remove_column :rdvs, :status, :rdv_status
    remove_column :rdvs_users, :status, :rdv_status
    execute(<<-SQL.squish
      DROP TYPE rdv_status
    SQL
           )

    # Recreate enum without waiting
    create_enum :rdv_status, %w[unknown seen excused revoked noshow]

    # Recreate status columns and index
    add_column :rdvs_users, :status, :rdv_status, null: false, default: :unknown
    add_index :rdvs_users, :status
    add_column :rdvs, :status, :rdv_status, null: false, default: :unknown
    add_index :rdvs, :status

    # Copy back temp_status to status
    execute(<<-SQL.squish
      UPDATE rdvs
      SET status = temp_status::rdv_status
    SQL
           )

    execute(<<-SQL.squish
      UPDATE rdvs_users
      SET status = temp_status::rdv_status
    SQL
           )

    # Remove temp columns
    remove_column :rdvs, :temp_status, :string
    remove_column :rdvs_users, :temp_status, :string
  end

  def migrate_waiting_statuses_to_unknown
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
  end

  def add_temp_status_and_copy_data
    add_column :rdvs, :temp_status, :string
    add_column :rdvs_users, :temp_status, :string

    execute(<<-SQL.squish
      UPDATE rdvs
      SET temp_status = status
    SQL
           )

    execute(<<-SQL.squish
      UPDATE rdvs_users
      SET temp_status = status
    SQL
           )
  end

  def down
    # We assume migrated "waiting" statuses will not be recovered in case of rollback
    add_enum_value :rdv_status, "waiting"
  end
end

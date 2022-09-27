# frozen_string_literal: true

class AddStatusToRdvsUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :rdvs_users, :status, :rdv_status, null: false, default: :unknown
    add_index :rdvs_users, :status

    up_only do
      execute(<<-SQL.squish
        UPDATE rdvs_users SET status = (SELECT status FROM rdvs WHERE rdvs_users.rdv_id = rdvs.id)
      SQL
             )
    end
  end
end

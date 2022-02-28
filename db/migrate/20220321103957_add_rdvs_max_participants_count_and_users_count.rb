# frozen_string_literal: true

class AddRdvsMaxParticipantsCountAndUsersCount < ActiveRecord::Migration[6.1]
  def change
    add_column :rdvs, :max_participants_count, :integer

    add_column :rdvs, :users_count, :integer

    add_index :rdvs, :max_participants_count
    add_index :rdvs, :users_count

    up_only do
      execute(<<-SQL.squish
        UPDATE rdvs SET users_count = (SELECT count(1) FROM rdvs_users WHERE rdvs_users.rdv_id = rdvs.id)
      SQL
             )
    end
  end
end

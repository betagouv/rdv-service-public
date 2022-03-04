# frozen_string_literal: true

class AddUsersCountToRdvs < ActiveRecord::Migration[6.1]
  def change
    add_column :rdvs, :rdv_collectif_users_count, :integer
  end
end

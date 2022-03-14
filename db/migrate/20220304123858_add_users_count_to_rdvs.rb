# frozen_string_literal: true

class AddUsersCountToRdvs < ActiveRecord::Migration[6.1]
  def change
    add_column :rdvs, :rdv_collectif_users_count, :integer

    up_only do
      Rdv.joins(:motif).where(motifs: { collectif: true }).pluck(:id).each do |rdv_id|
        Rdv.reset_counters(rdv_id, :users)
      end
    end
  end
end

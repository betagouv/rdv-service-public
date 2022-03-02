# frozen_string_literal: true

class AddRdvMaxParticipantsCount < ActiveRecord::Migration[6.1]
  def change
    add_column :rdvs, :max_participants_count, :integer
  end
end

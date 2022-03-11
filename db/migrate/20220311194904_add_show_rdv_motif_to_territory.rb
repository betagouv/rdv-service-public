# frozen_string_literal: true

class AddShowRdvMotifToTerritory < ActiveRecord::Migration[6.1]
  def change
    add_column :territories, :show_rdv_motif, :boolean, default: false

    Territory.update_all(show_rdv_motif: true) # rubocop:disable Rails/SkipsModelValidations
  end
end

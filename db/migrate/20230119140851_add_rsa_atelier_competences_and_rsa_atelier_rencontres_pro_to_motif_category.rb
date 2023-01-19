# frozen_string_literal: true

class AddRsaAtelierCompetencesAndRsaAtelierRencontresProToMotifCategory < ActiveRecord::Migration[7.0]
  def change
    add_enum_value :motif_category, "rsa_atelier_competences"
    add_enum_value :motif_category, "rsa_atelier_rencontres_pro"
  end
end

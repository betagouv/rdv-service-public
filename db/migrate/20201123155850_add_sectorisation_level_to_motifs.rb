class AddSectorisationLevelToMotifs < ActiveRecord::Migration[6.0]
  def up
    add_column :motifs, :sectorisation_level, :string, default: "departement"
    enabled_departements = ENV["SECTORISATION_ENABLED_DEPARTMENT_LIST"]&.split
    Motif
      .joins(:organisation)
      .where(organisations: { departement: enabled_departements })
      .update_all(sectorisation_level: Motif::SECTORISATION_LEVEL_ORGANISATION)
    Motif
      .joins(:organisation)
      .where.not(organisations: { departement: enabled_departements })
      .update_all(sectorisation_level: Motif::SECTORISATION_LEVEL_DEPARTEMENT)
  end

  def down
    remove_column :motifs, :sectorisation_level
  end
end

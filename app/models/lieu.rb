class Lieu < ApplicationRecord
  belongs_to :organisation

  validates :name, :address, :telephone, :horaires, presence: true

  def full_name
    "#{name} (#{address})"
  end

  def self.for_motif_and_departement_from_time(_motif_name, departement, time)
    organisations_ids = Organisation.where(departement: departement)
    Lieu.where(organisation: organisations_ids)

    motifs_ids = Motif.where(organisation_id: organisations_ids)
    lieux_ids = PlageOuverture.where("first_day < ?", time).joins(:motifs).where(motifs: { id: motifs_ids }).pluck(:lieu_id).uniq
    Lieu.where(id: lieux_ids)
  end
end

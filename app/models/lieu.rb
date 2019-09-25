class Lieu < ApplicationRecord
  belongs_to :organisation

  validates :name, :address, :telephone, :horaires, presence: true

  def full_name
    "#{name} (#{address})"
  end

  def self.for_motif_and_departement_in_date_range(motif_name, departement, date_range)
    organisations_ids = Organisation.where(departement: departement)
    motifs_ids = Motif.online.where(organisation_id: organisations_ids, name: motif_name)
    lieux_ids = PlageOuverture.joins(:motifs).where(motifs: { id: motifs_ids }).pluck(:lieu_id).uniq
    Lieu.where(id: lieux_ids)
  end
end

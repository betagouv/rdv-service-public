class Lieu < ApplicationRecord
  belongs_to :organisation
  has_many :plage_ouvertures
  validates :name, :address, :telephone, :horaires, presence: true

  def full_name
    "#{name} (#{address})"
  end

  def self.for_motif_and_departement(motif_name, departement)
    motifs_ids = Motif.active.online.joins(:organisation).where(organisations: { departement: departement }, name: motif_name)
    lieux_ids = PlageOuverture
                .where.not("recurrence IS ? AND first_day < ?", nil, Time.zone.today)
                .joins(:motifs).where(motifs: { id: motifs_ids })
                .map(&:lieu_id).uniq
    Lieu.where(id: lieux_ids)
  end
end

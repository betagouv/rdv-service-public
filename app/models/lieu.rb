class Lieu < ApplicationRecord
  belongs_to :organisation
  has_many :plage_ouvertures
  validates :name, :address, presence: true

  scope :for_motif, lambda { |motif|
    lieux_ids = PlageOuverture
                .where.not("recurrence IS ? AND first_day < ?", nil, Time.zone.today)
                .joins(:motifs).where(motifs: { id: motif.id, deleted_at: nil })
                .map(&:lieu_id).uniq
    where(id: lieux_ids)
  }

  scope :for_motif_and_departement, lambda { |motif_name, departement|
    motifs_ids = Motif.active.online.joins(:organisation).where(organisations: { departement: departement }, name: motif_name)
    lieux_ids = PlageOuverture
                .where.not("recurrence IS ? AND first_day < ?", nil, Time.zone.today)
                .joins(:motifs).where(motifs: { id: motifs_ids })
                .map(&:lieu_id).uniq
    where(id: lieux_ids)
  }

  scope :for_service_motif_and_departement, lambda { |service_id, motif_name, departement|
    motifs_ids = Motif.active.online.joins(:organisation).where(organisations: { departement: departement }, name: motif_name, service_id: service_id)
    lieux_ids = PlageOuverture
                .where.not("recurrence IS ? AND first_day < ?", nil, Time.zone.today)
                .joins(:motifs).where(motifs: { id: motifs_ids })
                .map(&:lieu_id).uniq
    where(id: lieux_ids)
  }

  def full_name
    "#{name} (#{address})"
  end
end

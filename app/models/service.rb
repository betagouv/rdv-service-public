class Service < ApplicationRecord
  has_many :pros, dependent: :nullify
  has_many :motifs, dependent: :destroy
  belongs_to :organisation
  validates :name, presence: true, uniqueness: { case_sensitive: false }

  def self.with_online_motif_in_departement(departement)
    online_motifs_id = Motif.online.active.joins(:organisation).where(organisations: {departement: departement}).joins(:plage_ouvertures).pluck(:service_id).uniq
    Service.where(id: online_motifs_id).includes(:motifs).merge(Motif.active).merge(Motif.online).references(:motifs)
  end
end
